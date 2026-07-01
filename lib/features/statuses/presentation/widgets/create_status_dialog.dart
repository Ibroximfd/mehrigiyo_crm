import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/create_status_form_bloc.dart';
import '../bloc/statuses_bloc.dart';

class CreateStatusDialog extends StatelessWidget {
  const CreateStatusDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateStatusFormBloc(),
      child: const _CreateStatusView(),
    );
  }
}

class _CreateStatusView extends StatelessWidget {
  const _CreateStatusView();

  void _submit(BuildContext context) {
    final formBloc = context.read<CreateStatusFormBloc>();
    final form = formBloc.state;
    if (!form.isNameValid) {
      formBloc.add(const FormSubmitPressed());
      return;
    }
    context.read<StatusesBloc>().add(StatusCreateRequested(
          name: form.name.trim(),
          category: form.category,
          color: form.color,
          isDefault: form.isDefault,
        ));
  }

  Future<void> _openCustomPicker(BuildContext context) async {
    final formBloc = context.read<CreateStatusFormBloc>();
    Color picked = _hexColor(formBloc.state.color);
    final result = await showDialog<Color>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Rang tanlash'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: picked,
            onColorChanged: (c) => picked = c,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: const Text('Bekor'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dctx).pop(picked),
            child: const Text('Tanlash'),
          ),
        ],
      ),
    );
    if (result != null) {
      formBloc.add(FormColorChanged(_toHex(result)));
    }
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
      buildWhen: (p, s) =>
          s is StatusMutating || s is StatusMutateError || s is StatusesLoaded,
      builder: (ctx, state) {
        final loading = state is StatusMutating;
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Yangi status',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _NameField(),
                  const SizedBox(height: 14),
                  const Text('Kategoriya',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  const _CategorySelector(),
                  const SizedBox(height: 14),
                  const Text('Rang',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 8),
                  _ColorSelector(onCustomTap: () => _openCustomPicker(ctx)),
                  const SizedBox(height: 14),
                  const _DefaultCheckbox(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: loading ? null : () => _submit(ctx),
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Yaratish'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateStatusFormBloc, CreateStatusFormState>(
      buildWhen: (p, c) => p.nameError != c.nameError,
      builder: (ctx, state) {
        return TextField(
          onChanged: (v) =>
              ctx.read<CreateStatusFormBloc>().add(FormNameChanged(v)),
          decoration: InputDecoration(
            labelText: 'Status nomi',
            prefixIcon: const Icon(Icons.label_rounded),
            errorText: state.nameError,
          ),
        );
      },
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateStatusFormBloc, CreateStatusFormState>(
      buildWhen: (p, c) => p.category != c.category,
      builder: (ctx, state) {
        final bloc = ctx.read<CreateStatusFormBloc>();
        return Row(
          children: [
            Expanded(
              child: _CategoryChip(
                label: 'Sotuv',
                selected: state.category == 'sales',
                onTap: () => bloc.add(const FormCategoryChanged('sales')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CategoryChip(
                label: 'Sotuv keyin',
                selected: state.category == 'post_sale',
                onTap: () => bloc.add(const FormCategoryChanged('post_sale')),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ColorSelector extends StatelessWidget {
  final VoidCallback onCustomTap;
  const _ColorSelector({required this.onCustomTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateStatusFormBloc, CreateStatusFormState>(
      buildWhen: (p, c) =>
          p.color != c.color || p.customColors != c.customColors,
      builder: (ctx, state) {
        final bloc = ctx.read<CreateStatusFormBloc>();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in state.swatches)
              _ColorDot(
                color: _hexColor(c),
                selected: state.color == c,
                onTap: () => bloc.add(FormColorChanged(c)),
              ),
            _AddColorButton(onTap: onCustomTap),
          ],
        );
      },
    );
  }
}

class _DefaultCheckbox extends StatelessWidget {
  const _DefaultCheckbox();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateStatusFormBloc, CreateStatusFormState>(
      buildWhen: (p, c) => p.isDefault != c.isDefault,
      builder: (ctx, state) {
        return Row(
          children: [
            Checkbox(
              value: state.isDefault,
              activeColor: AppColors.primary,
              onChanged: (v) => ctx
                  .read<CreateStatusFormBloc>()
                  .add(FormDefaultToggled(v ?? false)),
            ),
            const Text('Default status', style: TextStyle(fontSize: 14)),
          ],
        );
      },
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
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
  }
}

class _AddColorButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddColorButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: const Icon(Icons.add, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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

Color _hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

String _toHex(Color c) {
  final argb = c.toARGB32().toRadixString(16).padLeft(8, '0');
  return '#${argb.substring(2).toUpperCase()}';
}
