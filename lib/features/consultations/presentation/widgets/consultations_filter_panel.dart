import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';

class ConsultationsFilterPanel extends StatefulWidget {
  final int? currentStatus;
  final ValueChanged<int?> onStatusChanged;
  final ValueChanged<String> onSearchChanged;

  const ConsultationsFilterPanel({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  @override
  State<ConsultationsFilterPanel> createState() =>
      _ConsultationsFilterPanelState();
}

class _ConsultationsFilterPanelState extends State<ConsultationsFilterPanel> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchInput(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      widget.onSearchChanged(value.trim());
    });
    setState(() {});
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    widget.onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 16 : 24,
        vertical: isPhone ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isPhone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchField(
                  controller: _searchController,
                  onChanged: _onSearchInput,
                  onClear: _clearSearch,
                ),
                const SizedBox(height: 10),
                SizedBox(height: 44, child: _StatusDropdown(
                  value: widget.currentStatus,
                  onChanged: widget.onStatusChanged,
                )),
              ],
            )
          : Row(
              children: [
                SizedBox(
                  width: 300,
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: _onSearchInput,
                    onClear: _clearSearch,
                  ),
                ),
                const SizedBox(width: 20),
                _StatusDropdown(
                  value: widget.currentStatus,
                  onChanged: widget.onStatusChanged,
                ),
              ],
            ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Ism yoki telefon bo\'yicha qidiruv...',
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textMuted,
          size: 20,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                onPressed: onClear,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: const BorderSide(color: AppColors.borderLight).style ==
                BorderStyle.solid
            ? Border.all(color: AppColors.borderLight)
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('Barchasi')),
            DropdownMenuItem(value: 1, child: Text('Yangi')),
            DropdownMenuItem(value: 2, child: Text('Jarayonda')),
            DropdownMenuItem(value: 3, child: Text('Tugallangan')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
