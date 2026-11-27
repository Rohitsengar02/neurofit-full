// Images and videos on Cloudflare R2 (free: 10 GB storage, no egress fees).
//   POST /api/media/presign  { fileName, contentType }  -> { uploadUrl, url }   (phone uploads directly to R2)
//   POST /api/media/upload   { imageBase64, mimeType, fileName, folder }  -> { url }  (admin panel's existing flow)
//   GET  /api/media          list uploaded files (admin media library)
//   DELETE /api/media?key=   delete a file (admin)
//   GET  /api/media/proxy?url=  fetch an R2/public image through the server (CORS-safe for web)
const express = require('express');
const crypto = require('crypto');
const { S3Client, PutObjectCommand, ListObjectsV2Command, DeleteObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const config = require('../config');
const { requireAuth, requireAdmin, isAdmin } = require('../lib/auth');
const cache = require('../lib/cache');

const router = express.Router();
const r2 = config.r2;
const configured = () => !!((r2.endpoint || r2.accountId) && r2.accessKeyId && r2.secretAccessKey && r2.bucket);
let client = null;
const s3 = () => client || (client = new S3Client({
  region: 'auto', endpoint: r2.endpoint || `https://${r2.accountId}.r2.cloudflarestorage.com`,
  credentials: { accessKeyId: r2.accessKeyId, secretAccessKey: r2.secretAccessKey },
}));

const ALLOWED = /^(image\/(jpeg|png|webp|gif|heic|heif|avif)|video\/(mp4|quicktime|webm))$/;
const EXT = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'image/gif': 'gif', 'image/heic': 'heic', 'image/heif': 'heif', 'image/avif': 'avif', 'video/mp4': 'mp4', 'video/quicktime': 'mov', 'video/webm': 'webm' };
const publicUrl = (key) => (r2.publicUrl ? `${r2.publicUrl}/${key}` : `/api/media/file/${encodeURIComponent(key)}`);
const safeFolder = (f, fallback) => (String(f || fallback).toLowerCase().replace(/[^a-z0-9/_-]/g, '').replace(/\.\./g, '').slice(0, 60) || fallback);

function keyFor(req, folder, contentType, fileName) {
  const ext = EXT[contentType] || (String(fileName || '').split('.').pop() || 'bin').toLowerCase().replace(/[^a-z0-9]/g, '').slice(0, 5);
  const base = isAdmin(req) ? safeFolder(folder, 'admin') : `users/${req.user.id}/${safeFolder(folder, 'uploads')}`;
  return `${base}/${Date.now().toString(36)}-${crypto.randomBytes(5).toString('hex')}.${ext}`;
}

function notConfigured(res) {
  return res.status(503).json({ success: false, code: 'r2_not_configured', message: 'Image storage is not set up on the server yet (R2 keys missing).' });
}

router.post('/presign', requireAuth, async (req, res) => {
  if (!configured()) return notConfigured(res);
  const contentType = String(req.body.contentType || req.body.mimeType || 'image/jpeg').toLowerCase();
  if (!ALLOWED.test(contentType)) return res.status(400).json({ success: false, message: 'Only images and short videos can be uploaded.' });
  const key = keyFor(req, req.body.folder, contentType, req.body.fileName);
  const uploadUrl = await getSignedUrl(s3(), new PutObjectCommand({ Bucket: r2.bucket, Key: key, ContentType: contentType, CacheControl: 'public, max-age=31536000, immutable' }), { expiresIn: 600 });
  res.json({ success: true, uploadUrl, method: 'PUT', headers: { 'Content-Type': contentType }, key, url: publicUrl(key) });
});

router.post('/upload', requireAuth, express.json({ limit: '25mb' }), async (req, res) => {
  if (!configured()) return notConfigured(res);
  const b64 = String(req.body.imageBase64 || req.body.base64 || req.body.data || '').replace(/^data:[^;]+;base64,/, '');
  if (!b64) return res.status(400).json({ success: false, message: 'No file data' });
  const contentType = String(req.body.mimeType || req.body.contentType || 'image/jpeg').toLowerCase();
  if (!ALLOWED.test(contentType)) return res.status(400).json({ success: false, message: 'Unsupported file type' });
  const body = Buffer.from(b64, 'base64');
  if (!isAdmin(req) && body.length > 8 * 1024 * 1024) return res.status(413).json({ success: false, message: 'File is larger than 8 MB' });
  const key = keyFor(req, req.body.folder || 'media', contentType, req.body.fileName);
  await s3().send(new PutObjectCommand({ Bucket: r2.bucket, Key: key, Body: body, ContentType: contentType, CacheControl: 'public, max-age=31536000, immutable' }));
  await cache.bump('media');
  const url = publicUrl(key);
  res.json({ success: true, url, imageUrl: url, key, fileName: req.body.fileName || key.split('/').pop(), data: { url, key } });
});

router.get('/', requireAdmin, cache.cached(['media'], 60), async (req, res) => {
  if (!configured()) return res.json({ success: true, count: 0, data: [], items: [], message: 'R2 not configured' });
  const out = await s3().send(new ListObjectsV2Command({ Bucket: r2.bucket, Prefix: req.query.prefix || undefined, MaxKeys: Math.min(Number(req.query.limit) || 500, 1000), ContinuationToken: req.query.cursor || undefined }));
  const items = (out.Contents || []).sort((a, b) => b.LastModified - a.LastModified).map((o) => ({ key: o.Key, url: publicUrl(o.Key), size: o.Size, lastModified: o.LastModified }));
  res.json({ success: true, count: items.length, data: items.map((i) => i.url), items, next: out.NextContinuationToken || null });
});

router.delete('/', requireAdmin, async (req, res) => {
  if (!configured()) return notConfigured(res);
  let key = String(req.query.key || req.body.key || '');
  if (!key && req.body.url && r2.publicUrl) key = String(req.body.url).replace(`${r2.publicUrl}/`, '');
  if (!key) return res.status(400).json({ success: false, message: 'key required' });
  await s3().send(new DeleteObjectCommand({ Bucket: r2.bucket, Key: key }));
  await cache.bump('media');
  res.json({ success: true });
});

// Serves a file when the bucket has no public URL.
router.get('/file/*', async (req, res) => {
  if (!configured()) return notConfigured(res);
  try {
    const obj = await s3().send(new GetObjectCommand({ Bucket: r2.bucket, Key: decodeURIComponent(req.params[0]) }));
    res.setHeader('Content-Type', obj.ContentType || 'application/octet-stream');
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    obj.Body.pipe(res);
  } catch (_) {
    res.status(404).end();
  }
});

// Image proxy for web builds (CORS). Only proxies our own R2 bucket and a few known image hosts.
const PROXY_HOSTS = [/\.r2\.dev$/, /\.r2\.cloudflarestorage\.com$/, /^raw\.githubusercontent\.com$/, /^images\.unsplash\.com$/, /^lh3\.googleusercontent\.com$/];
router.get('/proxy', async (req, res) => {
  let u;
  try { u = new URL(String(req.query.url || '')); } catch (_) { return res.status(400).end(); }
  const own = r2.publicUrl && String(req.query.url).startsWith(r2.publicUrl);
  if (u.protocol !== 'https:' || (!own && !PROXY_HOSTS.some((re) => re.test(u.hostname)))) return res.status(403).end();
  try {
    const r = await fetch(u, { redirect: 'follow' });
    if (!r.ok) return res.status(r.status).end();
    res.setHeader('Content-Type', r.headers.get('content-type') || 'image/jpeg');
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.end(Buffer.from(await r.arrayBuffer()));
  } catch (_) {
    res.status(502).end();
  }
});

router.get('/status', (_req, res) => res.json({ success: true, configured: configured(), publicUrl: r2.publicUrl || null }));

module.exports = { router, configured, s3 };
