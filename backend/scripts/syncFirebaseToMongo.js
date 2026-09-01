const axios = require('axios');
const connectDB = require('../config/db');
const Product = require('../models/Product');
const Category = require('../models/Category');
const Banner = require('../models/Banner');
const LayoutSection = require('../models/LayoutSection');
const User = require('../models/User');
const Address = require('../models/Address');
const Order = require('../models/Order');

const projectId = 'neurofit-9877b';
const baseUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

const fetchFirestoreCollection = async (colName) => {
  try {
    const res = await axios.get(`${baseUrl}/${colName}`);
    return res.data.documents || [];
  } catch (err) {
    console.error(`Failed to fetch ${colName} from Firestore: ${err.message}`);
    return [];
  }
};

const parseVal = (v) => {
  if (!v) return null;
  if (v.stringValue !== undefined) return v.stringValue;
  if (v.integerValue !== undefined) return parseInt(v.integerValue);
  if (v.doubleValue !== undefined) return parseFloat(v.doubleValue);
  if (v.booleanValue !== undefined) return v.booleanValue;
  if (v.arrayValue !== undefined) return (v.arrayValue.values || []).map(parseVal);
  if (v.mapValue !== undefined) {
    const obj = {};
    for (const [k, f] of Object.entries(v.mapValue.fields || {})) {
      obj[k] = parseVal(f);
    }
    return obj;
  }
  return null;
};

const parseFields = (fields) => {
  const result = {};
  for (const [k, v] of Object.entries(fields || {})) {
    result[k] = parseVal(v);
  }
  return result;
};

const syncAll = async () => {
  await connectDB();
  console.log('🚀 Starting Full Migration & Sync from Firestore REST API to MongoDB Atlas...');

  // 1. PRODUCTS
  const prodDocs = await fetchFirestoreCollection('products');
  console.log(`📦 Syncing ${prodDocs.length} Products...`);
  for (const doc of prodDocs) {
    const id = doc.name.split('/').last || doc.name.split('/').pop();
    const data = parseFields(doc.fields);
    await Product.findOneAndUpdate({ id }, { ...data, id }, { upsert: true });
  }

  // 2. CATEGORIES
  const catDocs = await fetchFirestoreCollection('categories');
  console.log(`🏷️ Syncing ${catDocs.length} Categories...`);
  for (const doc of catDocs) {
    const id = doc.name.split('/').last || doc.name.split('/').pop();
    const data = parseFields(doc.fields);
    await Category.findOneAndUpdate({ id }, { ...data, id }, { upsert: true });
  }

  // 3. BANNERS
  const banDocs = await fetchFirestoreCollection('banners');
  console.log(`🎨 Syncing ${banDocs.length} Banners...`);
  for (const doc of banDocs) {
    const id = doc.name.split('/').last || doc.name.split('/').pop();
    const data = parseFields(doc.fields);
    await Banner.findOneAndUpdate({ id }, { ...data, id }, { upsert: true });
  }

  // 4. LAYOUT SECTIONS
  const layoutDocs = await fetchFirestoreCollection('layout_sections');
  console.log(`📐 Syncing ${layoutDocs.length} Layout Sections...`);
  for (const doc of layoutDocs) {
    const id = doc.name.split('/').last || doc.name.split('/').pop();
    const data = parseFields(doc.fields);
    await LayoutSection.findOneAndUpdate({ id }, { ...data, id }, { upsert: true });
  }

  // 5. ORDERS
  const orderDocs = await fetchFirestoreCollection('orders');
  console.log(`🚚 Syncing ${orderDocs.length} Orders...`);
  for (const doc of orderDocs) {
    const orderId = doc.name.split('/').last || doc.name.split('/').pop();
    const data = parseFields(doc.fields);
    await Order.findOneAndUpdate({ orderId }, { ...data, orderId }, { upsert: true });
  }

  // 6. USERS & SUBCOLLECTION ADDRESSES
  const userDocs = await fetchFirestoreCollection('users');
  console.log(`👤 Syncing ${userDocs.length} Users & Addresses...`);
  for (const doc of userDocs) {
    const uid = doc.name.split('/').last || doc.name.split('/').pop();
    const data = parseFields(doc.fields);
    await User.findOneAndUpdate({ uid }, { ...data, uid }, { upsert: true });

    // Fetch user address subcollection
    try {
      const addrRes = await axios.get(`${baseUrl}/users/${uid}/address`);
      const addrDocs = addrRes.data.documents || [];
      for (const aDoc of addrDocs) {
        const aData = parseFields(aDoc.fields);
        await Address.findOneAndUpdate({ uid }, { ...aData, uid }, { upsert: true });
      }
    } catch (e) {
      // Ignore if no address subcollection
    }
  }

  console.log('✅ ALL COLLECTIONS & SUBCOLLECTIONS MIGRATED AND SYNCED TO MONGODB ATLAS!');
  process.exit(0);
};

syncAll();
