import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/statuses_bloc.dart';

class CreateStatusDialog extends StatefulWidget {
  const CreateStatusDialog({super.key});

  @override
  State<CreateStatusDialog> createState() => _CreateStatusDialogState();
}

class _CreateStatusDialogState extends State<CreateStatusDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _category = 'sales';
  String _color = '#6b7280';
  bool _isDefault = false;

  static const _colors = [
    '#6b7280', '#0D6A55', '#1AAB87', '#F59E0B',
    '#DC3545', '#3B82F6', '#8B5CF6', '#EC4899',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    ctx.read<StatusesBloc>().add(StatusCreateRequested(
      name: _nameCtrl.text.trim(),
      category: _category,
      color: _color,
      isDefault: _isDefault,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StatusesBloc, StatusesState>(
      listenWhen: (_, s) => s is StatusesLoaded || s is StatusMutateError,
      listener: (ctx, state) {
        if (state is StatusesLoaded) {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text('Status yaratildi'),
            backgroundColor: AppColors.success,
          ));
        } else if (state is StatusMutateError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
          ));
        }
      },
      buildWhen: (p, s) => s is StatusMutating || s is StatusMutateError || s is StatusesLoaded,
      builder: (ctx, state) {
        final loading = state is StatusMutating;
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Yangi status',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Status nomi',
                        prefixIcon: Icon(Icons.label_rounded),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nom kiritilishi shart' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('Kategoriya', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 6),
                    StatefulBuilder(
                      builder: (_, setS) => Row(
                        children: [
                          Expanded(
                            child: _CategoryChip(
                              label: 'Sotuv',
                              selected: _category == 'sales',
                              onTap: () {
                                setS(() => _category = 'sales');
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CategoryChip(
                              label: 'Sotuv keyin',
                              selected: _category == 'post_sale',
                              onTap: () {
                                setS(() => _category = 'post_sale');
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Rang', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colors.map((c) {
                        final selected = _color == c;
                        return GestureDetector(
                          onTap: () => setState(() => _color = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _hexColor(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? AppColors.textPrimary : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: selected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Checkbox(
                          value: _isDefault,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _isDefault = v ?? false),
                        ),
                        const Text('Default status', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: loading ? null : () => _submit(ctx),
                      child: loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Yaratish'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _hexColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
