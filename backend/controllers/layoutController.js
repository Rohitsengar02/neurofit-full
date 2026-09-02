const LayoutSection = require('../models/LayoutSection');

// Helper to broadcast full active sections list to all connected clients
const broadcastLayoutSections = async (io) => {
  if (!io) return;
  try {
    const sections = await LayoutSection.find().sort({ sortOrder: 1, displayOrder: 1, createdAt: 1 });
    io.emit('layout_sections_updated', sections);
  } catch (err) {
    console.error('Error broadcasting layout sections:', err);
  }
};

// 1. GET ALL LAYOUT SECTIONS
exports.getAllLayoutSections = async (req, res) => {
  try {
    const { activeOnly } = req.query;
    const filter = {};
    if (activeOnly === 'true') {
      filter.isActive = true;
    }

    const sections = await LayoutSection.find(filter).sort({ sortOrder: 1, displayOrder: 1, createdAt: 1 });
    res.json({
      success: true,
      count: sections.length,
      data: sections,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 2. GET SINGLE LAYOUT SECTION BY ID
exports.getLayoutSectionById = async (req, res) => {
  try {
    const secId = req.params.id;
    const section = await LayoutSection.findOne({
      $or: [{ id: secId }, { sectionId: secId }],
    });

    if (!section) {
      return res.status(404).json({ success: false, message: 'Layout Section not found' });
    }

    res.json({ success: true, data: section });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 3. CREATE NEW LAYOUT SECTION
exports.createLayoutSection = async (req, res) => {
  try {
    const secId = req.body.id || req.body.sectionId || `sec_${Date.now()}`;
    const payload = {
      ...req.body,
      id: secId,
      sectionId: secId,
    };

    const section = new LayoutSection(payload);
    await section.save();

    // Broadcast Socket.io events
    if (req.io) {
      req.io.emit('layout_section_created', section);
      await broadcastLayoutSections(req.io);
    }

    console.log(`✅ [HOME LAYOUT] Section Created: "${section.title}" (${section.id})`);
    res.status(201).json({ success: true, data: section });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 4. UPDATE EXISTING LAYOUT SECTION
exports.updateLayoutSection = async (req, res) => {
  try {
    const secId = req.params.id;
    const section = await LayoutSection.findOneAndUpdate(
      { $or: [{ id: secId }, { sectionId: secId }] },
      { ...req.body, updatedAt: new Date() },
      { new: true, upsert: true }
    );

    // Broadcast Socket.io events
    if (req.io) {
      req.io.emit('layout_section_updated', section);
      await broadcastLayoutSections(req.io);
    }

    console.log(`✅ [HOME LAYOUT] Section Updated: "${section.title}" (${section.id})`);
    res.json({ success: true, data: section });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 5. TOGGLE SECTION ACTIVE STATUS
exports.toggleLayoutSectionStatus = async (req, res) => {
  try {
    const secId = req.params.id;
    const { isActive, status } = req.body;

    const section = await LayoutSection.findOne({
      $or: [{ id: secId }, { sectionId: secId }],
    });

    if (!section) {
      return res.status(404).json({ success: false, message: 'Layout Section not found' });
    }

    if (typeof isActive === 'boolean') {
      section.isActive = isActive;
    } else if (status) {
      section.isActive = status.toLowerCase() === 'active';
    } else {
      section.isActive = !section.isActive;
    }

    section.updatedAt = new Date();
    await section.save();

    if (req.io) {
      req.io.emit('layout_section_updated', section);
      await broadcastLayoutSections(req.io);
    }

    console.log(`✅ [HOME LAYOUT] Section Status Toggled: "${section.title}" (Active: ${section.isActive})`);
    res.json({ success: true, data: section });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 6. REORDER SECTIONS BATCH
exports.reorderLayoutSections = async (req, res) => {
  try {
    const { sectionOrders } = req.body; // Array of { id: string, sortOrder: number }
    if (!Array.isArray(sectionOrders)) {
      return res.status(400).json({ success: false, message: 'sectionOrders must be an array' });
    }

    const updates = sectionOrders.map((item) =>
      LayoutSection.updateOne(
        { $or: [{ id: item.id }, { sectionId: item.id }] },
        { $set: { sortOrder: item.sortOrder, displayOrder: item.sortOrder, updatedAt: new Date() } }
      )
    );

    await Promise.all(updates);

    if (req.io) {
      req.io.emit('layout_sections_reordered', sectionOrders);
      await broadcastLayoutSections(req.io);
    }

    console.log(`✅ [HOME LAYOUT] Reordered ${sectionOrders.length} sections`);
    res.json({ success: true, message: 'Sections reordered successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 7. DELETE LAYOUT SECTION
exports.deleteLayoutSection = async (req, res) => {
  try {
    const secId = req.params.id;
    const deleted = await LayoutSection.findOneAndDelete({
      $or: [{ id: secId }, { sectionId: secId }],
    });

    if (req.io) {
      req.io.emit('layout_section_deleted', { id: secId, sectionId: secId });
      await broadcastLayoutSections(req.io);
    }

    console.log(`✅ [HOME LAYOUT] Section Deleted: (${secId})`);
    res.json({ success: true, message: 'Layout Section deleted successfully from MongoDB Atlas', deleted });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
