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
    if (total <= 7) return List.generate(total, (index) => index + 1);
    if (current <= 4) return [1, 2, 3, 4, 5, '...', total];
    if (current >= total - 3) {
      return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
    }
    return [1, '...', current - 1, current, current + 1, '...', total];
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final items = _buildPages(totalPages, page);

    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            _navButton(
              label: 'ก่อนหน้า',
              enabled: page > 1,
              onTap: () => onPageChanged(page - 1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: items.map((item) {
                    if (item == '...') {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '...',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    }
                    final value = item as int;
                    final isActive = value == page;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onPageChanged(value),
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '$value',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _navButton(
              label: 'ถัดไป',
              enabled: page < totalPages,
              onTap: () => onPageChanged(page + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _navButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? onTap : null,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
