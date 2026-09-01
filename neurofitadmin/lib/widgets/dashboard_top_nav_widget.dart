import 'package:flutter/material.dart';

class DashboardTopNavWidget extends StatelessWidget {
  final List<Map<String, dynamic>> primaryCategories;
  final int selectedCategoryIndex;
  final Function(int) onCategorySelected;

  const DashboardTopNavWidget({
    super.key,
    required this.primaryCategories,
    required this.selectedCategoryIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(primaryCategories.length, (index) {
            final cat = primaryCategories[index];
            final isSelected = selectedCategoryIndex == index;
            final color = (cat['color'] as Color?) ?? const Color(0xFF6366F1);
            final icon = (cat['icon'] as IconData?) ?? Icons.category_rounded;
            final name = cat['name'] as String;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onCategorySelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 78,
                  height: 74,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withOpacity(0.32),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Circular Icon on Top
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white.withOpacity(0.22) : color.withOpacity(0.12),
                        ),
                        child: Icon(
                          icon,
                          size: 16,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                      // Title with Ellipsis at Bottom
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
