import 'package:flutter/material.dart';

class PrimaryLoadingButton extends StatelessWidget {
  const PrimaryLoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey<String>('loading'),
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : Row(
                  key: const ValueKey<String>('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(label),
                    if (icon != null) ...<Widget>[
                      const SizedBox(width: 8),
                      Icon(icon, size: 19),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
