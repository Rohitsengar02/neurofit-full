const axios = require('axios');
const io = require('socket.io-client');

const API_BASE = 'http://localhost:5000/api/layout';
const SOCKET_URL = 'http://localhost:5000';

async function runTest() {
  console.log('🚀 Starting Home Layout CRUD & Socket.io Verification Test...\n');

  // 1. Connect Socket.io Client
  const socket = io(SOCKET_URL);
  const eventsReceived = [];

  socket.on('connect', () => {
    console.log('🔌 Socket.io Client Connected:', socket.id);
  });

  socket.on('layout_section_created', (data) => {
    console.log('📡 [EVENT: layout_section_created] Received:', data.title, `(${data.id})`);
    eventsReceived.push('layout_section_created');
  });

  socket.on('layout_section_updated', (data) => {
    console.log('📡 [EVENT: layout_section_updated] Received:', data.title, `(${data.id})`);
    eventsReceived.push('layout_section_updated');
  });

  socket.on('layout_section_deleted', (data) => {
    console.log('📡 [EVENT: layout_section_deleted] Received:', data.id);
    eventsReceived.push('layout_section_deleted');
  });

  socket.on('layout_sections_updated', (data) => {
    console.log('📡 [EVENT: layout_sections_updated] Received sections count:', data.length);
    eventsReceived.push('layout_sections_updated');
  });

  await new Promise((resolve) => setTimeout(resolve, 800));

  try {
    // 2. CREATE SECTION (POST /api/layout)
    const testId = `sec_test_${Date.now()}`;
    console.log('\n1️⃣ Testing POST /api/layout (Create)...');
    const createRes = await axios.post(API_BASE, {
      id: testId,
      sectionId: testId,
      title: 'Trending Supplements & Proteins',
      subtitle: 'Handpicked top sellers for your daily nutrition',
      showTitle: true,
      type: 'products',
      layoutMode: 'carousel',
      filterSource: 'category',
      filterId: 'cat_supplements',
      filterName: 'Supplements',
      itemLimit: 6,
      sortOrder: 1,
      isActive: true,
    });
    console.log('✅ Create Status:', createRes.status, 'Title:', createRes.data.data?.title);

    await new Promise((resolve) => setTimeout(resolve, 600));

    // 3. GET ALL SECTIONS (GET /api/layout)
    console.log('\n2️⃣ Testing GET /api/layout (List)...');
    const listRes = await axios.get(API_BASE);
    console.log('✅ Total Layout Sections:', listRes.data.count);

    // 4. GET SINGLE SECTION (GET /api/layout/:id)
    console.log(`\n3️⃣ Testing GET /api/layout/${testId}...`);
    const singleRes = await axios.get(`${API_BASE}/${testId}`);
    console.log('✅ Fetched Title:', singleRes.data.data?.title);

    // 5. UPDATE SECTION (PUT /api/layout/:id)
    console.log(`\n4️⃣ Testing PUT /api/layout/${testId} (Update)...`);
    const updateRes = await axios.put(`${API_BASE}/${testId}`, {
      title: 'Top Whey Proteins & BCAA',
      layoutMode: 'grid',
    });
    console.log('✅ Updated Title:', updateRes.data.data?.title, 'Mode:', updateRes.data.data?.layoutMode);

    await new Promise((resolve) => setTimeout(resolve, 600));

    // 6. TOGGLE STATUS (PATCH /api/layout/:id/status)
    console.log(`\n5️⃣ Testing PATCH /api/layout/${testId}/status...`);
    const statusRes = await axios.patch(`${API_BASE}/${testId}/status`, { isActive: false });
    console.log('✅ New Active Status:', statusRes.data.data?.isActive);

    await new Promise((resolve) => setTimeout(resolve, 600));

    // 7. DELETE SECTION (DELETE /api/layout/:id)
    console.log(`\n6️⃣ Testing DELETE /api/layout/${testId}...`);
    const deleteRes = await axios.delete(`${API_BASE}/${testId}`);
    console.log('✅ Delete Message:', deleteRes.data.message);

    await new Promise((resolve) => setTimeout(resolve, 800));

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
