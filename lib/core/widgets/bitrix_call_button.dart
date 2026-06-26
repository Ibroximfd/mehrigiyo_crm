import 'package:flutter/material.dart';
import '../utils/bitrix_helper.dart';

/// Round green "call via Bitrix24" button. Stateless, no BLoC — tapping just
/// opens the Bitrix24 click-to-call URL in a new tab.
///
/// Renders nothing when [phone] is null/empty.
class BitrixCallButton extends StatelessWidget {
  final String? phone;
  final double size;

  const BitrixCallButton({super.key, this.phone, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final p = phone;
    if (p == null || p.trim().isEmpty) return const SizedBox.shrink();

    return Tooltip(
      message: 'Bitrix24 orqali qo\'ng\'iroq qilish',
      child: Material(
        color: Colors.green.shade50,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => launchBitrixCall(p),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.call,
              size: size * 0.55,
              color: Colors.green.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
