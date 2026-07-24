import 'package:flutter/material.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';

class PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  List<dynamic> _buildPages(int total, int current) {
    if (total <= 5) return List.generate(total, (index) => index + 1);

    if (current <= 3) {
      return [1, 2, 3, 4, '...', total];
    }
    if (current >= total - 2) {
      return [1, '...', total - 3, total - 2, total - 1, total];
    }
    return [1, '...', current - 1, current, current + 1, '...', total];
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final items = _buildPages(totalPages, page);

    return Column(
      children: [
        const SizedBox(height: 24),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _navButton(
                icon: Icons.chevron_left_rounded,
                enabled: page > 1,
                onTap: () => onPageChanged(page - 1),
              ),
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: items.map((item) {
                  if (item == '...') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '...',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 18,
                        ),
                      ),
                    );
                  }
                  final value = item as int;
                  final isActive = value == page;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: isActive ? null : () => onPageChanged(value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? Colors.grey[200]
                              : Colors.transparent,
                        ),
                        child: Text(
                          '$value',
                          style: TextStyle(
                            fontWeight: isActive
                                ? FontWeight.w500
                                : FontWeight.normal,
                            fontSize: 16,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 4),
              _navButton(
                icon: Icons.chevron_right_rounded,
                enabled: page < totalPages,
                onTap: () => onPageChanged(page + 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 24,
          color: enabled
              ? AppColors.textPrimary
              : AppColors.textMuted.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
