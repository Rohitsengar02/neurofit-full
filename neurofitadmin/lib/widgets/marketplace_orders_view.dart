import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/category_backend_service.dart';
import '../constants/api_constants.dart';
import 'skeleton_loader.dart';

class MarketplaceOrdersView extends StatefulWidget {
  final String selectedDateRange;
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;

  const MarketplaceOrdersView({
    super.key,
    required this.selectedDateRange,
    required this.fadeAnimations,
    required this.slideAnimations,
  });

  @override
  State<MarketplaceOrdersView> createState() => _MarketplaceOrdersViewState();
}

class _MarketplaceOrdersViewState extends State<MarketplaceOrdersView> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';
  IO.Socket? _socket;

  final List<String> _statusFilters = [
    'All',
    'Placed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _initSocket();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _initSocket() {
    try {
      final socketUri = ApiConstants.socketUrl;
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder().setTransports(['websocket', 'polling']).disableAutoConnect().build(),
      );

      _socket?.connect();

      _socket?.on('order:created', (data) {
        debugPrint('⚡ [ADMIN SOCKET] New Order Created: $data');
        _fetchOrders(silent: true);
      });
      _socket?.on('admin:new_order', (data) {
        _fetchOrders(silent: true);
      });
      _socket?.on('order:updated', (data) {
        debugPrint('⚡ [ADMIN SOCKET] Order Updated: $data');
        _fetchOrders(silent: true);
      });
      _socket?.on('order_status_updated', (data) {
        _fetchOrders(silent: true);
      });
      _socket?.on('order:deleted', (data) {
        _fetchOrders(silent: true);
      });
    } catch (e) {
      debugPrint('Error init admin socket: $e');
    }
  }

  Future<void> _fetchOrders({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    final candidateUrls = ApiConstants.candidateBaseUrls.map((b) => '$b/api/orders').toList();

    for (final url in candidateUrls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final rawData = (body['data'] ?? body) as List<dynamic>? ?? [];
          final List<Map<String, dynamic>> parsed = rawData.map((e) => Map<String, dynamic>.from(e as Map)).toList();

          if (mounted) {
            setState(() {
              _orders = parsed;
              _isLoading = false;
            });
          }
          return;
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    final candidateUrls = ApiConstants.candidateBaseUrls.map((b) => '$b/api/orders/$orderId/status').toList();

    for (final url in candidateUrls) {
      try {
        final res = await http.put(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'orderStatus': newStatus}),
        );
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order #$orderId updated to "$newStatus" 🎉'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _fetchOrders(silent: true);
          return;
        }
      } catch (_) {}
    }
  }

  void _showOrderDetailModal(Map<String, dynamic> o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminOrderDetailSheet(
        order: o,
        onStatusUpdated: (newStatus) {
          final id = o['orderId'] ?? o['id'] ?? o['_id'];
          if (id != null) {
            _updateOrderStatus(id.toString(), newStatus);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _orders.where((o) {
      final status = (o['orderStatus'] ?? o['status'] ?? '').toString();
      final matchesStatus = _selectedStatusFilter == 'All' || status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      final customer = (o['customerName'] ?? o['fullName'] ?? o['name'] ?? '').toString().toLowerCase();
      final orderId = (o['orderId'] ?? o['id'] ?? '').toString().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || customer.contains(_searchQuery.toLowerCase()) || orderId.contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top CMS Header Bar
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shopping_cart_checkout_rounded, color: Color(0xFF10B981), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Marketplace Orders Feed',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(
                                '${_orders.length} Real Orders Syncing via Socket.io',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Refresh Orders Feed',
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                    onPressed: () => _fetchOrders(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Input
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Search by Order ID or Customer Name...',
                    hintStyle: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                    prefixIcon: Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusFilters.map((st) {
                    final isSelected = _selectedStatusFilter == st;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedStatusFilter = st),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            st,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Orders List
        if (_isLoading && _orders.isEmpty)
          const SkeletonListView(count: 4)
        else if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              children: const [
                Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFF94A3B8)),
                SizedBox(height: 10),
                Text('No Orders Found', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                SizedBox(height: 4),
                Text('Orders placed by athletes will stream here in real-time.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final o = filtered[index];
              return _buildOrderCard(o);
            },
          ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    final orderId = o['orderId'] ?? o['id'] ?? o['_id'] ?? 'NF-ORD';
    final customer = o['customerName'] ?? o['shippingAddress']?['fullName'] ?? o['shippingAddress']?['name'] ?? 'Athlete Customer';
    final phone = o['phoneNumber'] ?? o['shippingAddress']?['phoneNumber'] ?? o['shippingAddress']?['phone'] ?? '';
    final totalAmount = (o['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final status = (o['orderStatus'] ?? o['status'] ?? 'Placed').toString();
    final createdAt = o['createdAt'] != null ? DateTime.tryParse(o['createdAt'].toString()) : null;
    final dateStr = createdAt != null ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}' : 'Recent';

    final List items = o['items'] is List ? o['items'] : (o['itemList'] is List ? o['itemList'] : []);
    final firstItem = items.isNotEmpty ? Map<String, dynamic>.from(items.first as Map) : null;
    final String firstImg = firstItem != null ? (firstItem['image'] ?? firstItem['imageUrl'] ?? firstItem['mainImageUrl'] ?? '') : '';

    Color statusColor = const Color(0xFF6366F1);
    Color statusBg = const Color(0xFFEEF2FF);

    switch (status.toLowerCase()) {
      case 'placed':
        statusColor = const Color(0xFF4F46E5);
        statusBg = const Color(0xFFEEF2FF);
        break;
      case 'processing':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        break;
      case 'shipped':
      case 'out for delivery':
        statusColor = const Color(0xFF0284C7);
        statusBg = const Color(0xFFE0F2FE);
        break;
      case 'delivered':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFDCFCE7);
        break;
      case 'cancelled':
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
        break;
    }

    return GestureDetector(
      onTap: () => _showOrderDetailModal(o),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      'Order #$orderId',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: firstImg.isNotEmpty
                      ? Image.network(
                          CategoryBackendService.getDisplayableImageUrl(firstImg),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.shopping_bag_rounded, size: 20, color: Color(0xFF64748B))),
                        )
                      : const Center(child: Icon(Icons.shopping_bag_rounded, size: 20, color: Color(0xFF64748B))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '👤 $customer ${phone.isNotEmpty ? "• $phone" : ""}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${items.length} Item(s) • $dateStr',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16, thickness: 0.8, color: Color(0xFFF1F5F9)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                ),
                const Row(
                  children: [
                    Text('Manage Status & Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF38BDF8))),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF38BDF8)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Order Detail Sheet for Admin
class _AdminOrderDetailSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(String) onStatusUpdated;

  const _AdminOrderDetailSheet({required this.order, required this.onStatusUpdated});

  @override
  State<_AdminOrderDetailSheet> createState() => _AdminOrderDetailSheetState();
}

class _AdminOrderDetailSheetState extends State<_AdminOrderDetailSheet> {
  late String _currentStatus;

  final List<String> _statuses = [
    'Placed',
    'Processing',
    'Shipped',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = (widget.order['orderStatus'] ?? widget.order['status'] ?? 'Placed').toString();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final orderId = o['orderId'] ?? o['id'] ?? o['_id'] ?? 'NF-ORD';
    final List items = o['items'] is List ? o['items'] : (o['itemList'] is List ? o['itemList'] : []);
    final address = o['shippingAddress'] is Map ? Map<String, dynamic>.from(o['shippingAddress']) : {};
    final double total = (o['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = o['paymentMethod'] ?? 'UPI';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 44, height: 4.5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #$orderId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('Payment: $paymentMethod • Total: ₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. UPDATE ORDER STATUS
                  const Text('1. Update Order Status (Syncs via Socket.io)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statuses.map((st) {
                      final isSel = _currentStatus.toLowerCase() == st.toLowerCase();
                      return ChoiceChip(
                        label: Text(st, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isSel ? Colors.white : const Color(0xFF0F172A))),
                        selected: isSel,
                        selectedColor: const Color(0xFF10B981),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _currentStatus = st);
                            widget.onStatusUpdated(st);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 2. ORDER ITEMS
                  const Text('2. Purchased Items', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  ...items.map((it) {
                    final itemMap = Map<String, dynamic>.from(it as Map);
                    final String title = itemMap['title'] ?? itemMap['name'] ?? 'Item';
                    final String variant = itemMap['variant'] ?? '';
                    final double price = (itemMap['price'] as num?)?.toDouble() ?? 0.0;
                    final int qty = (itemMap['quantity'] as num?)?.toInt() ?? 1;
                    final String img = itemMap['image'] ?? itemMap['imageUrl'] ?? itemMap['mainImageUrl'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: img.isNotEmpty
                                ? Image.network(
                                    CategoryBackendService.getDisplayableImageUrl(img),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.shopping_bag_rounded, size: 18, color: Color(0xFF64748B))),
                                  )
                                : const Center(child: Icon(Icons.shopping_bag_rounded, size: 18, color: Color(0xFF64748B))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                if (variant.isNotEmpty)
                                  Text(variant, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                Text('Qty: $qty • Unit Price: ₹${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Text('₹${(price * qty).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // 3. SHIPPING & CUSTOMER DETAILS
                  const Text('3. Customer & Shipping Address', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Customer Name', address['fullName'] ?? address['name'] ?? o['customerName'] ?? 'N/A'),
                        _buildRow('Phone Number', address['phoneNumber'] ?? address['phone'] ?? o['phoneNumber'] ?? 'N/A'),
                        _buildRow('Street Address', address['streetAddress'] ?? 'N/A'),
                        _buildRow('City / Area', '${address['city'] ?? ''} ${address['area'] ?? ''} ${address['pincode'] ?? ''}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          Expanded(child: Text(val, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }
}
