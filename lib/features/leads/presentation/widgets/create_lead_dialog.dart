import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/leads_bloc.dart';

class CreateLeadDialog extends StatefulWidget {
  const CreateLeadDialog({super.key});

  @override
  State<CreateLeadDialog> createState() => _CreateLeadDialogState();
}

class _CreateLeadDialogState extends State<CreateLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _source = 'manual';

  static const _sources = {
    'manual': 'Qo\'lda',
    'app': 'Ilova',
    'instagram': 'Instagram',
    'facebook': 'Facebook',
  };

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _regionCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    ctx.read<LeadsBloc>().add(LeadCreateRequested(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      source: _source,
      region: _regionCtrl.text.trim().isEmpty ? null : _regionCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LeadsBloc, LeadsState>(
      listenWhen: (_, s) => s is LeadCreated || s is LeadCreateError,
      listener: (ctx, state) {
        if (state is LeadCreated) {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text('Lead muvaffaqiyatli qo\'shildi'),
            backgroundColor: AppColors.success,
          ));
        } else if (state is LeadCreateError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
          ));
        }
      },
      buildWhen: (_, s) => s is LeadCreating || s is LeadCreated || s is LeadCreateError,
      builder: (ctx, state) {
        final loading = state is LeadCreating;
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_add_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Yangi mijoz',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Mijoz ismi *',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Ism kiritilishi shart' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Telefon raqami *',
                                prefixIcon: Icon(Icons.phone_rounded),
                                hintText: '998901234567',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Telefon kiritilishi shart';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _regionCtrl,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Hudud (ixtiyoriy)',
                                prefixIcon: Icon(Icons.location_on_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _source,
                              decoration: const InputDecoration(
                                labelText: 'Manba',
                                prefixIcon: Icon(Icons.source_rounded),
                              ),
                              items: _sources.entries
                                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                  .toList(),
                              onChanged: (v) => setState(() => _source = v ?? 'manual'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _noteCtrl,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Izoh (ixtiyoriy)',
                                prefixIcon: Icon(Icons.notes_rounded),
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loading ? null : () => _submit(ctx),
                      child: loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Saqlash'),
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
}
