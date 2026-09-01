import 'package:flutter/material.dart';

class DashboardSubNavWidget extends StatelessWidget {
  final List<Map<String, dynamic>> subActions;
  final int selectedSubActionIndex;
  final Color activeCatColor;
  final bool isSubNavLoading;
  final AnimationController subNavStaggerController;
  final Function(int) onSubActionSelected;

  const DashboardSubNavWidget({
    super.key,
    required this.subActions,
    required this.selectedSubActionIndex,
    required this.activeCatColor,
    required this.isSubNavLoading,
    required this.subNavStaggerController,
    required this.onSubActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (subActions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(subActions.length, (index) {
            final item = subActions[index];
            final title = item['title'] as String;
            final isSelected = selectedSubActionIndex == index;
            final icon = (item['icon'] as IconData?) ?? Icons.insights_rounded;
            final color = (item['color'] as Color?) ?? activeCatColor;
            final badge = item['badge'];
            final badgeColor = (item['badgeColor'] as Color?) ?? const Color(0xFFEF4444);

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => onSubActionSelected(index),
                child: SizedBox(
                  width: 68,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Circular Icon Container with Active Color ONLY
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? color : const Color(0xFFF1F5F9),
                            ),
                            child: Icon(
                              icon,
                              size: 18,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Title with Ellipsis at Bottom
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: isSelected ? color : const Color(0xFF64748B),
                              letterSpacing: -0.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Badge Counter
                      if (badge != null)
                        Positioned(
                          top: -2,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1.2),
                            ),
                            child: Text(
                              badge.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
