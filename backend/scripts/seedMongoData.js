const connectDB = require('../config/db');
const Product = require('../models/Product');
const Category = require('../models/Category');
const Banner = require('../models/Banner');
const LayoutSection = require('../models/LayoutSection');

const seedData = async () => {
  await connectDB();
  console.log('🌱 Seeding MongoDB Atlas with initial database collections...');

  // 1. Categories
  const categories = [
    { id: 'cat_supplements', name: 'Supplements', imageUrl: 'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?w=600', description: 'Proteins, BCAAs, Creatine' },
    { id: 'cat_apparel', name: 'Apparel & Wear', imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600', description: 'Gym tops, hoodies, compression gear' },
    { id: 'cat_gear', name: 'Fitness Equipment', imageUrl: 'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=600', description: 'Dumbbells, resistance bands, mats' },
    { id: 'cat_footwear', name: 'Performance Shoes', imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600', description: 'Pro runners, training sneakers' }
  ];
  for (const c of categories) {
    await Category.findOneAndUpdate({ id: c.id }, c, { upsert: true });
  }

  // 2. Banners
  const banners = [
    {
      id: 'ban_1',
      title: 'SUMMER SHRED SALE',
      subtitle: 'Up to 40% OFF Premium Whey Isolates',
      imageUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=1200',
      badgeText: 'HOT DEAL 🔥',
      ctaText: 'Shop Whey',
      targetCategory: 'cat_supplements',
      displayOrder: 1
    },
    {
      id: 'ban_2',
      title: 'NEXT-GEN PRO RUNNERS',
      subtitle: 'Ultralight Cushioning & Neon Design',
      imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=1200',
      badgeText: 'NEW DROP ⚡',
      ctaText: 'Explore Gear',
      targetCategory: 'cat_footwear',
      displayOrder: 2
    }
  ];
  for (const b of banners) {
    await Banner.findOneAndUpdate({ id: b.id }, b, { upsert: true });
  }

  // 3. Products
  const products = [
    {
      id: 'prod_whey_1',
      title: 'Gold Standard 100% Whey Isolate',
      description: '24g Pure Whey Isolate per serving with ultra-fast absorption for lean muscle growth.',
      price: 3499.0,
      regularPrice: 4299.0,
      stock: 50,
      categoryName: 'Supplements',
      categoryId: 'cat_supplements',
      brand: 'Optimum Nutrition',
      mainImageUrl: 'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?w=800',
      status: 'active'
    },
    {
      id: 'prod_shoe_1',
      title: 'Pro Runner Neon X1',
      description: 'Engineered mesh upper with responsive neon nitrogen foam midsole.',
      price: 4999.0,
      regularPrice: 6499.0,
      stock: 30,
      categoryName: 'Performance Shoes',
      categoryId: 'cat_footwear',
      brand: 'NeuroFit',
      mainImageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
      status: 'active'
    },
    {
      id: 'prod_hoodie_1',
      title: 'Casual Hoodie Black + Shaker',
      description: 'Thermal cotton blend athletic hoodie with fleece lining.',
      price: 1899.0,
      regularPrice: 2499.0,
      stock: 45,
      categoryName: 'Apparel & Wear',
      categoryId: 'cat_apparel',
      brand: 'NeuroFit Apparel',
      mainImageUrl: 'https://images.unsplash.com/photo-1509967419530-da38b4704bc6?w=800',
      status: 'active'
    }
  ];
  for (const p of products) {
    await Product.findOneAndUpdate({ id: p.id }, p, { upsert: true });
  }

  // 4. Layout Sections
  const layoutSections = [
    {
      id: 'sec_featured',
      title: 'Trending Essentials 🔥',
      subtitle: 'Top rated gear loved by athletes',
      layoutType: 'grid',
      productIds: ['prod_whey_1', 'prod_shoe_1', 'prod_hoodie_1'],
      sortOrder: 1
    }
  ];
  for (const s of layoutSections) {
    await LayoutSection.findOneAndUpdate({ id: s.id }, s, { upsert: true });
  }

  console.log('✅ MongoDB Atlas Seed Completed Successfully!');
  process.exit(0);
};

seedData();
