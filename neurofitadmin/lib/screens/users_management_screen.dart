import 'package:flutter/material.dart';

class UsersManagementScreen extends StatelessWidget {
  const UsersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [
      {'name': 'Rohit Verma', 'email': 'rohitverma@gmail.com', 'plan': 'Pro Athlete', 'time': 'Joined 2 days ago', 'status': 'Active', 'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&h=120&fit=crop'},
      {'name': 'Sneha Kapoor', 'email': 'sneha.kapoor@gmail.com', 'plan': 'AI Coach+', 'time': 'Joined 5 days ago', 'status': 'Active', 'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&h=120&fit=crop'},
      {'name': 'Arjun Singh', 'email': 'arjun.singh@gmail.com', 'plan': 'Free Tier', 'time': 'Joined 1 week ago', 'status': 'Active', 'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=120&h=120&fit=crop'},
      {'name': 'Ananya Desai', 'email': 'ananya.desai@gmail.com', 'plan': 'Pro Athlete', 'time': 'Joined 2 weeks ago', 'status': 'Pending Verification', 'avatar': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=120&h=120&fit=crop'},
      {'name': 'Karan Mehta', 'email': 'karan.mehta@gmail.com', 'plan': 'Elite Trainer', 'time': 'Joined 1 month ago', 'status': 'Active', 'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&h=120&fit=crop'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text('User Management', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF10B981)), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                hintText: 'Search 52,689 users...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),

          ...users.map((u) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(u['avatar']!),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(u['name']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(u['plan']!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(u['email']!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(height: 2),
                      Text(u['time']!, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
