const axios = require('axios');
const io = require('socket.io-client');

const API_BASE = 'http://localhost:5000/api/banners';
const SOCKET_URL = 'http://localhost:5000';

async function runTest() {
  console.log('🚀 Starting Banner CRUD & Socket.io Verification Test...\n');

  // 1. Connect Socket.io Client
  const socket = io(SOCKET_URL);
  const eventsReceived = [];

  socket.on('connect', () => {
    console.log('🔌 Socket.io Test Client Connected:', socket.id);
  });

  socket.on('banner_created', (data) => {
    console.log('📡 [EVENT: banner_created] Received:', data.title, `(${data.id})`);
    eventsReceived.push('banner_created');
  });

  socket.on('banner_updated', (data) => {
    console.log('📡 [EVENT: banner_updated] Received:', data.title, `(${data.id})`);
    eventsReceived.push('banner_updated');
  });

  socket.on('banner_deleted', (data) => {
    console.log('📡 [EVENT: banner_deleted] Received:', data.id);
    eventsReceived.push('banner_deleted');
  });

  socket.on('banners_updated', (data) => {
    console.log('📡 [EVENT: banners_updated] Received list count:', data.length);
    eventsReceived.push('banners_updated');
  });

  // Wait for socket connection
  await new Promise((resolve) => setTimeout(resolve, 1000));

  try {
    // 2. CREATE BANNER (POST /api/banners)
    const testId = `banner_test_${Date.now()}`;
    console.log('\n1️⃣ Testing POST /api/banners (Create)...');
    const createRes = await axios.post(API_BASE, {
      id: testId,
      bannerId: testId,
      title: 'Mega Summer Sale 50% Off',
      subtitle: 'Premium NeuroFit Supplements',
      imageUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/1788017942289_scaled_1000013160.jpg',
      targetType: 'category',
      targetId: 'cat_supplements',
      targetName: 'Supplements & Nutrition',
      buttonText: 'Claim 50% Off',
      badge: 'LIMITED TIME',
      discountCode: 'SUMMER50',
      sortOrder: 1,
      status: 'Active',
    });
    console.log('✅ Create Status:', createRes.status, 'ID:', createRes.data.data?.id);

    await new Promise((resolve) => setTimeout(resolve, 800));

    // 3. GET ALL BANNERS (GET /api/banners)
    console.log('\n2️⃣ Testing GET /api/banners (List)...');
    const listRes = await axios.get(API_BASE);
    console.log('✅ Total Banners in Atlas:', listRes.data.count);

    // 4. GET SINGLE BANNER (GET /api/banners/:id)
    console.log(`\n3️⃣ Testing GET /api/banners/${testId}...`);
    const singleRes = await axios.get(`${API_BASE}/${testId}`);
    console.log('✅ Fetched Title:', singleRes.data.data?.title);

    // 5. UPDATE BANNER (PUT /api/banners/:id)
    console.log(`\n4️⃣ Testing PUT /api/banners/${testId} (Update)...`);
    const updateRes = await axios.put(`${API_BASE}/${testId}`, {
      title: 'Mega Summer Sale 70% Off (FLASH SALE)',
      buttonText: 'Shop Flash Sale',
    });
    console.log('✅ Updated Title:', updateRes.data.data?.title);

    await new Promise((resolve) => setTimeout(resolve, 800));

    // 6. TOGGLE STATUS (PATCH /api/banners/:id/status)
    console.log(`\n5️⃣ Testing PATCH /api/banners/${testId}/status...`);
    const statusRes = await axios.patch(`${API_BASE}/${testId}/status`, { status: 'Inactive' });
    console.log('✅ New Status:', statusRes.data.data?.status, 'isActive:', statusRes.data.data?.isActive);

    await new Promise((resolve) => setTimeout(resolve, 800));

    // 7. DELETE BANNER (DELETE /api/banners/:id)
    console.log(`\n6️⃣ Testing DELETE /api/banners/${testId}...`);
    const deleteRes = await axios.delete(`${API_BASE}/${testId}`);
    console.log('✅ Delete Message:', deleteRes.data.message);

    await new Promise((resolve) => setTimeout(resolve, 1200));

    console.log('\n🎉 SUMMARY OF RECEIVED SOCKET.IO EVENTS:');
    console.log(eventsReceived);

    socket.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('❌ Test Failed:', err.response ? err.response.data : err.message);
    socket.disconnect();
    process.exit(1);
  }
}

runTest();
