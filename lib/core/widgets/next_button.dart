import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/providers/theme_provider.dart';

class NextButton extends ConsumerWidget {
  final VoidCallback onTap;
  final String text;
  final bool disabled;

  const NextButton({
    super.key,
    required this.onTap,
    required this.text,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeProvider);

    return themeAsync.when(
      data: (theme) => GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: disabled
                ? Colors.grey.withOpacity(0.3)
                : theme.primaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: disabled ? Colors.grey : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox(),
    );
  }
}