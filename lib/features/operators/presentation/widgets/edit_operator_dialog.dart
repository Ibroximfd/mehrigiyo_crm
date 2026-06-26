import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/operator_entity.dart';
import '../bloc/operators_bloc.dart';

/// Admin-only edit dialog. Prefills the operator's current data and PATCHes only
/// the fields that actually changed. Leaving the password blank keeps the old
/// one; entering a new one resets it without an SMS code (admin is trusted).
///
/// Re-assigning an account to a new operator is the same flow: change full name +
/// username + password — no new account needed.
class EditOperatorDialog extends StatefulWidget {
  final OperatorEntity operator;
  const EditOperatorDialog({super.key, required this.operator});

  @override
  State<EditOperatorDialog> createState() => _EditOperatorDialogState();
}

class _EditOperatorDialogState extends State<EditOperatorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  final _passCtrl = TextEditingController();
  late final TextEditingController _commCtrl;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.operator.fullName);
    _usernameCtrl = TextEditingController(text: widget.operator.username);
    _commCtrl = TextEditingController(text: widget.operator.commissionPercent);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _commCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;

    final op = widget.operator;
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final pass = _passCtrl.text;
    final commText = _commCtrl.text.trim();

    // Only send what changed (PATCH semantics).
    final fullName = name != op.fullName ? name : null;
    final newUsername = username != op.username ? username : null;
    final password = pass.isNotEmpty ? pass : null;

    final newComm = double.tryParse(commText);
    final oldComm = double.tryParse(op.commissionPercent);
    final commission =
        (newComm != null && newComm != oldComm) ? newComm.toStringAsFixed(2) : null;

    if (fullName == null &&
        newUsername == null &&
        password == null &&
        commission == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Hech narsa o\'zgartirilmadi'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    ctx.read<OperatorsBloc>().add(OperatorUpdateRequested(
          id: op.id,
          fullName: fullName,
          username: newUsername,
          password: password,
          commissionPercent: commission,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OperatorsBloc, OperatorsState>(
      listenWhen: (_, s) => s is OperatorUpdated || s is OperatorUpdateError,
      listener: (ctx, state) {
        if (state is OperatorUpdated) {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text('Operator muvaffaqiyatli yangilandi'),
            backgroundColor: AppColors.success,
          ));
        } else if (state is OperatorUpdateError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
          ));
        }
      },
      buildWhen: (_, s) =>
          s is OperatorUpdating || s is OperatorUpdated || s is OperatorUpdateError,
      builder: (ctx, state) {
        final loading = state is OperatorUpdating;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.manage_accounts_rounded,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Operatorni tahrirlash',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'To\'liq ismi',
                        prefixIcon: const Icon(Icons.badge_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Ism kiritilishi shart' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _usernameCtrl,
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Login (username)',
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                        hintText: 'karimov_seller',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Login kiritilishi shart';
                        if (v.trim().length < 3) return 'Login kamida 3 ta belgi';
                        if (v.contains(' ')) return 'Login bo\'sh joy bo\'lmasin';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Yangi parol',
                        helperText: 'Bo\'sh qoldirsangiz parol o\'zgarmaydi',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        // Optional — only validate when a new password is entered.
                        if (v != null && v.isNotEmpty && v.length < 4) {
                          return 'Parol kamida 4 ta belgi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _commCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Komissiya (%)',
                        prefixIcon: const Icon(Icons.percent_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 100) return '0–100 oralig\'ida';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : () => _submit(ctx),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Saqlash',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
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
