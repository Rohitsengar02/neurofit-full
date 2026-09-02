const axios = require('axios');

const images = [
  '1788015825487_scaled_1000013160.jpg',
  '1788016244744_scaled_1000013160.jpg',
  '1788016956574_scaled_1000007700.jpg',
  '1788017119945_scaled_1000014014.jpg',
  '1788017942289_scaled_1000013160.jpg',
  '1788017945371_scaled_1000013988.jpg',
  '1788017947511_scaled_1000013992.jpg'
];

async function testAll() {
  for (const img of images) {
    const url = `https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/${img}`;
    try {
      const res = await axios.head(url);
      console.log('✅ Found:', img, res.status, res.headers['content-length']);
    } catch (e) {
      console.error('❌ Missing:', img, e.message);
    }
  }
}

testAll();
