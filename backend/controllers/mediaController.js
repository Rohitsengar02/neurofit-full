const { S3Client, ListObjectsV2Command, GetObjectCommand } = require('@aws-sdk/client-s3');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const Product = require('../models/Product');
const Category = require('../models/Category');
const SubCategory = require('../models/SubCategory');
const Banner = require('../models/Banner');

const uploadDir = path.join(__dirname, '../public/uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const s3Client = new S3Client({
  region: 'auto',
  endpoint: process.env.CLOUDFLARE_R2_S3_ENDPOINT || 'https://61519b8c6a1a20d3535eb39e85687539.r2.cloudflarestorage.com',
  credentials: {
    accessKeyId: process.env.CLOUDFLARE_R2_ACCESS_KEY_ID || '83e598b2d02375f5719eb04eaedfc77e',
    secretAccessKey: process.env.CLOUDFLARE_R2_SECRET_ACCESS_KEY || 'bfd40c9b9f43b4d6f02c7d328465f6f659d85d847dd3a097ec2e20adad9dc79f',
  },
});

const knownUploadedR2Images = new Set([
  '1788015825487_scaled_1000013160.jpg',
  '1788016244744_scaled_1000013160.jpg',
  '1788016956574_scaled_1000007700.jpg',
  '1788017119945_scaled_1000014014.jpg',
  '1788017942289_scaled_1000013160.jpg',
  '1788017945371_scaled_1000013988.jpg',
  '1788017947511_scaled_1000013992.jpg',
  'scaled_Untitled_design.png',
]);

exports.getR2MediaImages = async (req, res) => {
  try {
    const urlSet = new Set();
    const publicDevUrl = process.env.CLOUDFLARE_R2_PUBLIC_DEV_URL || 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev';
    const bucketName = process.env.CLOUDFLARE_R2_BUCKET_NAME || 'neurofit';

    // 1. Add known and local files
    for (const key of knownUploadedR2Images) {
      urlSet.add(`${publicDevUrl}/uploads/${key}`);
    }

    try {
      const localFiles = fs.readdirSync(uploadDir);
      for (const f of localFiles) {
        urlSet.add(`${publicDevUrl}/uploads/${f}`);
      }
    } catch (_) {}

    // 2. Query S3 Bucket objects if credentials active
    try {
      const command = new ListObjectsV2Command({ Bucket: bucketName, MaxKeys: 1000, Prefix: 'uploads/' });
      const r2Response = await s3Client.send(command);

      if (r2Response.Contents && r2Response.Contents.length > 0) {
        for (const obj of r2Response.Contents) {
          if (obj.Key) {
            const cleanKey = obj.Key.startsWith('/') ? obj.Key.substring(1) : obj.Key;
            urlSet.add(`${publicDevUrl}/${cleanKey}`);
          }
        }
      }
    } catch (r2Err) {}

    // 3. Include all R2 image/video URLs from MongoDB Collections
    let workoutCategories = [];
    try {
      const WorkoutCategory = require('../models/WorkoutCategory');
      workoutCategories = await WorkoutCategory.find().select('mediaUrl').lean();
    } catch (_) {}

    const [products, categories, subcategories, banners] = await Promise.all([
      Product.find().select('mainImageUrl additionalImages').lean(),
      Category.find().select('imageUrl').lean(),
      SubCategory.find().select('imageUrl').lean(),
      Banner.find().select('imageUrl').lean(),
    ]);

    for (const p of products) {
      if (p.mainImageUrl && p.mainImageUrl.includes('r2.dev')) urlSet.add(p.mainImageUrl);
      if (p.additionalImages && Array.isArray(p.additionalImages)) {
        for (const img of p.additionalImages) {
          if (img && img.includes('r2.dev')) urlSet.add(img);
        }
      }
    }

    for (const c of categories) {
      if (c.imageUrl && c.imageUrl.includes('r2.dev')) urlSet.add(c.imageUrl);
    }

    for (const s of subcategories) {
      if (s.imageUrl && s.imageUrl.includes('r2.dev')) urlSet.add(s.imageUrl);
    }

    for (const b of banners) {
      if (b.imageUrl && b.imageUrl.includes('r2.dev')) urlSet.add(b.imageUrl);
    }

    for (const w of workoutCategories) {
      if (w.mediaUrl && w.mediaUrl.includes('r2.dev')) urlSet.add(w.mediaUrl);
    }

    const allR2Images = Array.from(urlSet).filter((url) => url && typeof url === 'string' && url.includes('r2.dev'));

    res.json({
      success: true,
      count: allR2Images.length,
      data: allR2Images,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.uploadMediaImage = async (req, res) => {
  try {
    const { fileName, imageBase64, mimeType } = req.body;
    if (!fileName || !imageBase64) {
      return res.status(400).json({ success: false, message: 'Missing fileName or imageBase64' });
    }

    const cleanFileName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
    const publicDevUrl = process.env.CLOUDFLARE_R2_PUBLIC_DEV_URL || 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev';
    const accountId = process.env.CLOUDFLARE_R2_ACCOUNT_ID || '61519b8c6a1a20d3535eb39e85687539';
    const bucketName = process.env.CLOUDFLARE_R2_BUCKET_NAME || 'neurofit';
    const token = process.env.CLOUDFLARE_R2_API_TOKEN || 'cfat_CUzcTemF5447Ag5mi2gIrcDGYyrMrHSrO9PY6q5Sc69f5185';

    const buffer = Buffer.from(imageBase64, 'base64');
    const finalMime = mimeType || 'image/jpeg';

    // 1. Save locally in Express public/uploads directory for instant zero-lag serving
    try {
      fs.writeFileSync(path.join(uploadDir, cleanFileName), buffer);
    } catch (fsErr) {
      console.warn('⚠️ Local file save warning:', fsErr.message);
    }

    // 2. Attempt Server-Side Cloudflare API PUT upload
    try {
      const r2Uri = `https://api.cloudflare.com/client/v4/accounts/${accountId}/r2/buckets/${bucketName}/objects/uploads/${cleanFileName}`;
      await axios.put(r2Uri, buffer, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': finalMime,
        },
        maxContentLength: 50 * 1024 * 1024,
        maxBodyLength: 50 * 1024 * 1024,
      });
    } catch (apiErr) {
      console.warn('⚠️ Server-side Cloudflare API upload warning:', apiErr.message);
    }

    knownUploadedR2Images.add(cleanFileName);

    const publicUrl = `${publicDevUrl}/uploads/${cleanFileName}`;
    console.log(`✅ [MEDIA IMAGE UPLOADED & SERVED] ${publicUrl}`);

    // Broadcast via Socket.io
    const io = req.app.get('socketio');
    if (io) {
      io.emit('media_uploaded', { url: publicUrl, fileName: cleanFileName });
    }

    res.json({
      success: true,
      url: publicUrl,
      localUrl: `http://localhost:5000/uploads/${cleanFileName}`,
      fileName: cleanFileName,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.serveMediaFile = async (req, res) => {
  try {
    const filename = req.params.filename.replace(/[^a-zA-Z0-9._-]/g, '_');
    const localFilePath = path.join(uploadDir, filename);

    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Cache-Control', 'public, max-age=31536000');

    const ext = path.extname(filename).toLowerCase();
    const mimeMap = {
      '.mp4': 'video/mp4',
      '.mov': 'video/quicktime',
      '.webm': 'video/webm',
      '.mkv': 'video/x-matroska',
      '.avi': 'video/x-msvideo',
      '.gif': 'image/gif',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.svg': 'image/svg+xml',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
    };
    const inferredMime = mimeMap[ext] || 'image/jpeg';

    // 1. Serve from local uploads directory if present
    if (fs.existsSync(localFilePath)) {
      res.setHeader('Content-Type', inferredMime);
      return res.sendFile(localFilePath);
    }

    // 2. Try S3 GetObject Command
    try {
      const bucketName = process.env.CLOUDFLARE_R2_BUCKET_NAME || 'neurofit';
      const command = new GetObjectCommand({ Bucket: bucketName, Key: `uploads/${filename}` });
      const s3Data = await s3Client.send(command);
      if (s3Data.Body) {
        res.setHeader('Content-Type', (s3Data.ContentType && s3Data.ContentType !== 'application/octet-stream') ? s3Data.ContentType : inferredMime);
        return s3Data.Body.pipe(res);
      }
    } catch (_) {}

    // 3. Fallback: Fetch directly from Cloudflare R2 Public Dev URL & stream + cache locally
    const publicDevUrl = process.env.CLOUDFLARE_R2_PUBLIC_DEV_URL || 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev';
    const r2CandidateUrls = [
      `${publicDevUrl}/uploads/${filename}`,
      `${publicDevUrl}/${filename}`,
    ];

    for (const r2Url of r2CandidateUrls) {
      try {
        const response = await axios({
          method: 'get',
          url: r2Url,
          responseType: 'arraybuffer',
          timeout: 6000,
        });

        if (response.status === 200 && response.data) {
          // Cache on local disk for instant subsequent loads
          try {
            fs.writeFileSync(localFilePath, response.data);
          } catch (_) {}

          res.setHeader('Content-Type', inferredMime);
          return res.send(response.data);
        }
      } catch (_) {}
    }

    res.status(404).send('Image not found');
  } catch (err) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.status(404).send('Image not found');
  }
};

exports.proxyMediaImage = async (req, res) => {
  try {
    const { url } = req.query;
    if (!url) {
      return res.status(400).send('Missing url parameter');
    }

    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Cache-Control', 'public, max-age=31536000');

    // 1. If file exists locally in uploads directory, serve directly
    const filename = url.split('/').pop().split('?')[0];
    const localFilePath = path.join(uploadDir, filename);
    if (fs.existsSync(localFilePath)) {
      return res.sendFile(localFilePath);
    }

    // 2. Fetch the image from Cloudflare R2 and stream with CORS headers
    try {
      const response = await axios({
        method: 'get',
        url: url,
        responseType: 'arraybuffer',
        timeout: 6000,
      });

      if (response.status === 200 && response.data) {
        try {
          fs.writeFileSync(localFilePath, response.data);
        } catch (_) {}

        res.setHeader('Content-Type', response.headers['content-type'] || 'image/jpeg');
        return res.send(response.data);
      }
    } catch (_) {
      // Try S3 GetObject fallback
      try {
        const bucketName = process.env.CLOUDFLARE_R2_BUCKET_NAME || 'neurofit';
        const command = new GetObjectCommand({ Bucket: bucketName, Key: `uploads/${filename}` });
        const s3Data = await s3Client.send(command);
        if (s3Data.Body) {
          res.setHeader('Content-Type', s3Data.ContentType || 'image/jpeg');
          return s3Data.Body.pipe(res);
        }
      } catch (s3Err) {}
    }

    res.status(404).send('Image not found');
  } catch (err) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.status(404).send('Image not found');
  }
};
