// Loads the real exercise library (1,324 exercises with GIFs) from the
// exercies-data repo into the `exercises` and `exercise-categories` collections.
// Runs once on an empty database. Admins can edit everything afterwards.
const path = require('path');
const { query, one, pool } = require('../db');
const cache = require('../lib/cache');

const MEDIA = 'https://raw.githubusercontent.com/Rohitsengar02/exercies-data/main';
const title = (s) => String(s || '').replace(/\b\w/g, (c) => c.toUpperCase());
const slug = (s) => String(s || '').toLowerCase().replace(/[^a-z0-9]+/g, '_');

async function seed() {
  const list = require(path.join(__dirname, 'exercises.json'));
  const cats = new Map();
  for (const e of list) {
    const id = `ec_${slug(e.category)}`;
    if (!cats.has(id)) cats.set(id, { id, categoryId: id, name: title(e.category), count: 0, imageUrl: `${MEDIA}/${e.image}` });
    cats.get(id).count++;
  }
  const rows = [];
  let i = 0;
  for (const c of cats.values()) {
    rows.push(['exercise-categories', c.id, { categoryId: c.id, id: c.id, name: c.name, title: c.name, imageUrl: c.imageUrl, exerciseCount: c.count, description: `${c.count} ${c.name.toLowerCase()} exercises`, status: 'Active', isActive: true }, ++i]);
  }
  i = 0;
  for (const e of list) {
    const catId = `ec_${slug(e.category)}`;
    const gif = `${MEDIA}/${e.gif}`;
    rows.push(['exercises', `ex_${e.id}`, {
      id: `ex_${e.id}`, exerciseId: e.id, title: title(e.name), name: title(e.name),
      categoryId: catId, categoryName: title(e.category), category: title(e.category), bodyPart: title(e.bodyPart),
      muscleGroup: title(e.target), primaryMuscle: title(e.muscle), secondaryMuscles: e.secondary.map(title),
      equipment: title(e.equipment), mediaUrl: gif, gifUrl: gif, imageUrl: `${MEDIA}/${e.image}`, mediaType: 'gif',
      imageFile: e.image.split('/').pop(), gifFile: e.gif.split('/').pop(),
      instructions: e.steps.join(' '), steps: e.steps, sets: 3, reps: '12', status: 'Active', isActive: true,
      source: 'exercies-data',
    }, ++i]);
  }
  for (let k = 0; k < rows.length; k += 300) {
    const chunk = rows.slice(k, k + 300);
    await query(
      `INSERT INTO docs (collection, id, data, sort_order)
       SELECT c, i, d::jsonb, s FROM unnest($1::text[], $2::text[], $3::text[], $4::float8[]) AS x(c, i, d, s)
       ON CONFLICT (collection, id) DO NOTHING`,
      [chunk.map((r) => r[0]), chunk.map((r) => r[1]), chunk.map((r) => JSON.stringify(r[2])), chunk.map((r) => r[3])]
    );
  }
  await cache.bump('exercises', 'exercise-categories');
  console.log(`[seed] exercises: ${list.length}, categories: ${cats.size}`);
}

async function seedIfEmpty() {
  const r = await one(`SELECT count(*)::int AS n FROM docs WHERE collection = 'exercises'`);
  if (r.n === 0) await seed();
}

module.exports = { seed, seedIfEmpty };

if (require.main === module) {
  seed().then(() => pool.end()).catch((e) => { console.error(e); process.exit(1); });
}
