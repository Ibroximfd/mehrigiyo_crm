import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/bulk_lead_input.dart';
import '../bloc/admin_leads_bloc.dart';

class BulkCreateLeadsDialog extends StatefulWidget {
  const BulkCreateLeadsDialog({super.key});

  @override
  State<BulkCreateLeadsDialog> createState() => _BulkCreateLeadsDialogState();
}

class _BulkCreateLeadsDialogState extends State<BulkCreateLeadsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _rows = <_RowData>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Start with 2 empty rows
    _rows.addAll([_RowData(), _RowData()]);
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    if (_rows.length >= 20) return;
    setState(() => _rows.add(_RowData()));
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final leads = _rows
        .where((r) => r.nameCtrl.text.trim().isNotEmpty && r.phoneCtrl.text.trim().isNotEmpty)
        .map((r) => BulkLeadInput(
              fullName: r.nameCtrl.text.trim(),
              phone: r.phoneCtrl.text.trim(),
              region: r.regionCtrl.text.trim(),
            ))
        .toList();

    if (leads.isEmpty) return;
    setState(() => _loading = true);
    context.read<AdminLeadsBloc>().add(AdminLeadsBulkCreateRequested(leads));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ko\'p lead qo\'shish',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Bir vaqtda maksimal 20 ta',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Header labels
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Ism *',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Telefon *',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Hudud',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(width: 32),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Form(
                  key: _formKey,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _rows.length,
                    itemBuilder: (_, i) => _LeadRow(
                      key: ValueKey(i),
                      data: _rows[i],
                      index: i + 1,
                      canRemove: _rows.length > 1,
                      onRemove: () => _removeRow(i),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_rows.length < 20)
                TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Qator qo\'shish'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0D6A55),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        '${_rows.length} ta lead qo\'shish',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowData {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final regionCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    regionCtrl.dispose();
  }
}

class _LeadRow extends StatelessWidget {
  final _RowData data;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  const _LeadRow({
    super.key,
    required this.data,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: data.nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ism Familiya',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? '' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: data.phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: '998901234567',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? '' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: data.regionCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Toshkent',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 28,
            child: canRemove
                ? IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  )
                : const SizedBox(height: 28),
          ),
        ],
      ),
    );
  }
}
