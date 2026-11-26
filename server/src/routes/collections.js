// Generic REST for every admin-managed collection. Same contract the admin
// panel and the user app already use:
//   GET    /api/<res>            list   (?activeOnly=true, ?categoryId=, ?q=, ?limit=, ?offset=, any ?field=value)
//   GET    /api/<res>/active     active items only
//   GET    /api/<res>/:id        one item
//   POST   /api/<res>            create (or update if the id exists)
//   PUT    /api/<res>/:id        update (creates if missing)
//   PATCH  /api/<res>/:id/status toggle / set active status
//   POST   /api/<res>/reorder    { items: [{ id, sortOrder }] } (any list in the body works)
//   DELETE /api/<res>/:id
// Reads are public and cached; writes need an admin token.
const express = require('express');
const docs = require('../lib/docs');
const { cached } = require('../lib/cache');
const { requireAdmin } = require('../lib/auth');

// resource path -> { collection, idField, prefix, search }
const RESOURCES = {
  products: { idField: 'id', prefix: 'prod', search: ['name', 'title', 'brand', 'categoryName'] },
  categories: { idField: 'id', prefix: 'cat' },
  subcategories: { idField: 'id', prefix: 'sub' },
  banners: { idField: 'bannerId', prefix: 'ban' },
  layout: { idField: 'sectionId', prefix: 'sec' },
  discounts: { idField: 'discountId', prefix: 'disc', search: ['code', 'title'] },
  workouts: { idField: 'id', prefix: 'wk', search: ['title', 'name', 'category'] },
  programs: { idField: 'id', prefix: 'prog', collection: 'fitness_programs' },
  exercises: { idField: 'id', prefix: 'ex', search: ['title', 'name', 'muscleGroup', 'equipment'] },
  'workout-categories': { idField: 'id', prefix: 'wcat' },
  'workout-banners': { idField: 'bannerId', prefix: 'wban' },
  'workout-layout': { idField: 'sectionId', prefix: 'wsec' },
  'workout-sections': { idField: 'id', prefix: 'wsi' },
  'exercise-categories': { idField: 'categoryId', prefix: 'ecat' },
  plans: { idField: 'planId', prefix: 'plan', collection: 'subscription_plans' },
  'fitness-cms': { idField: 'itemId', prefix: 'cms', collection: 'fitness_cms' },
  foods: { idField: 'id', prefix: 'food', search: ['name', 'category'] },
  recipes: { idField: 'id', prefix: 'rec', search: ['name', 'title', 'category'] },
  'diet-plans': { idField: 'id', prefix: 'diet', collection: 'diet_plans', search: ['name', 'title'] },
  challenges: { idField: 'id', prefix: 'chal' },
  vendors: { idField: 'id', prefix: 'ven', search: ['name', 'storeName', 'email'] },
  'app-settings': { idField: 'id', prefix: 'set', collection: 'app_settings' },
};

const RESERVED_QUERY = new Set(['activeOnly', 'q', 'search', 'limit', 'offset', 'page', 'sort', 'order', 'key', 'uid', 't', '_']);

const isActive = (item) => item.isActive !== false && String(item.status || 'active').toLowerCase() !== 'inactive' && String(item.status || '').toLowerCase() !== 'draft';

function build(resource, cfg) {
  const collection = cfg.collection || resource;
  const r = express.Router();
  const map = (rows) => rows.map((row) => docs.toItem(row, cfg.idField));

  r.get('/', cached([collection], 300), async (req, res) => {
    const filters = {};
    for (const [k, v] of Object.entries(req.query)) {
      if (!RESERVED_QUERY.has(k) && typeof v === 'string') filters[k] = v;
    }
    // subcategories: the app filters by categoryId; stored as parentCategoryId
    if (resource === 'subcategories' && filters.categoryId) {
      filters.parentCategoryId = filters.categoryId;
      delete filters.categoryId;
    }
    const limit = Number(req.query.limit) || 1000;
    const page = Number(req.query.page) || 0;
    const offset = Number(req.query.offset) || (page > 1 ? (page - 1) * limit : 0);
    let rows = await docs.list(collection, {
      filters,
      search: req.query.q || req.query.search,
      searchFields: cfg.search,
      limit,
      offset,
      order: req.query.sort === 'new' ? 'new' : 'sort',
    });
    let data = map(rows);
    if (req.query.activeOnly === 'true') data = data.filter(isActive);
    res.json({ success: true, count: data.length, data });
  });

  r.get('/active', cached([collection], 300), async (_req, res) => {
    const data = map(await docs.list(collection)).filter(isActive);
    res.json({ success: true, count: data.length, data });
  });

  r.post('/reorder', requireAdmin, async (req, res) => {
    const lists = Array.isArray(req.body) ? [req.body] : Object.values(req.body || {}).filter(Array.isArray);
    const pairs = [];
    lists.flat().forEach((o, i) => {
      if (typeof o === 'string') return pairs.push({ id: o, sort: i + 1 });
      if (!o || typeof o !== 'object') return;
      const id = o.id ?? o.sectionId ?? o.bannerId ?? o.categoryId ?? o._id;
      const sort = o.sortOrder ?? o.displayOrder ?? o.order ?? i + 1;
      if (id !== undefined) pairs.push({ id, sort });
    });
    await docs.setSort(collection, pairs);
    res.json({ success: true, message: 'Reordered' });
  });

  r.get('/:id', cached([collection], 300), async (req, res) => {
    const row = await docs.find(collection, req.params.id);
    if (!row) return res.status(404).json({ success: false, message: 'Not found' });
    res.json({ success: true, data: docs.toItem(row, cfg.idField) });
  });

  r.post('/', requireAdmin, async (req, res) => {
    const body = req.body || {};
    const given = body[cfg.idField] ?? body.id ?? body._id;
    const id = given === undefined || given === null || given === '' ? docs.newId(cfg.prefix) : String(given);
    const row = await docs.upsert(collection, id, { ...body, [cfg.idField]: id });
    res.status(201).json({ success: true, data: docs.toItem(row, cfg.idField) });
  });

  const update = async (req, res) => {
    const existing = await docs.find(collection, req.params.id);
    const id = existing ? existing.id : req.params.id;
    const row = await docs.upsert(collection, id, { ...req.body, [cfg.idField]: id });
    res.status(existing ? 200 : 201).json({ success: true, data: docs.toItem(row, cfg.idField) });
  };
  r.put('/:id', requireAdmin, update);
  r.patch('/:id', requireAdmin, update);

  const status = async (req, res) => {
    const existing = await docs.find(collection, req.params.id);
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    const cur = existing.data.isActive !== false && String(existing.data.status || 'active').toLowerCase() !== 'inactive';
    const b = req.body || {};
    const next = b.isActive !== undefined ? b.isActive === true || b.isActive === 'true'
      : b.status !== undefined ? String(b.status).toLowerCase() === 'active' : !cur;
    const row = await docs.upsert(collection, existing.id, { isActive: next, status: next ? 'Active' : 'Inactive' });
    res.json({ success: true, data: docs.toItem(row, cfg.idField) });
  };
  r.patch('/:id/status', requireAdmin, status);
  r.put('/:id/status', requireAdmin, status);
  r.post('/:id/status', requireAdmin, status);

  r.delete('/:id', requireAdmin, async (req, res) => {
    const existing = await docs.find(collection, req.params.id);
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    await docs.remove(collection, existing.id);
    res.json({ success: true, message: 'Deleted' });
  });

  return r;
}

function mount(app, extra = {}) {
  for (const [resource, cfg] of Object.entries(RESOURCES)) {
    if (extra[resource]) app.use(`/api/${resource}`, extra[resource]);
    app.use(`/api/${resource}`, build(resource, cfg));
  }
}

module.exports = { mount, RESOURCES, isActive };
