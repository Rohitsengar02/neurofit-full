const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const Product = require('./models/Product');
  const Category = require('./models/Category');
  const SubCategory = require('./models/SubCategory');
  const Banner = require('./models/Banner');

  const prods = await Product.find().lean();
  const cats = await Category.find().lean();
  const subs = await SubCategory.find().lean();
  const bans = await Banner.find().lean();

  console.log('--- ALL PRODUCT MAIN IMAGES ---');
  prods.forEach(p => console.log(p.title, '=>', p.mainImageUrl));

  console.log('--- ALL CATEGORY IMAGES ---');
  cats.forEach(c => console.log(c.name, '=>', c.imageUrl));

  console.log('--- ALL BANNER IMAGES ---');
  bans.forEach(b => console.log(b.title, '=>', b.imageUrl));

  mongoose.disconnect();
});
