import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../operator_chat/domain/entities/chat_entities.dart';
import '../../../operator_chat/domain/usecases/chat_usecases.dart';
import '../../domain/entities/operator_order_entity.dart';
import '../bloc/operator_order_bloc.dart';

enum _OrderMode { fromRecommendation, manual }

class CreateOperatorOrderDialog extends StatefulWidget {
  /// Pre-filled phone from lead or chat participant
  final String phone;

  /// If set → "from recommendation" mode
  final int? recommendationId;

  /// Optional lead context
  final int? leadId;

  const CreateOperatorOrderDialog({
    super.key,
    required this.phone,
    this.recommendationId,
    this.leadId,
  });

  @override
  State<CreateOperatorOrderDialog> createState() => _CreateOperatorOrderDialogState();
}

class _CreateOperatorOrderDialogState extends State<CreateOperatorOrderDialog> {
  late _OrderMode _mode;
  final _notesCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  // Manual mode state
  final Map<int, int> _quantities = {}; // productId → quantity
  List<ChatProductEntity> _products = [];
  bool _productsLoading = false;
  bool _productsHasMore = false;
  int _productsPage = 1;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _mode = widget.recommendationId != null ? _OrderMode.fromRecommendation : _OrderMode.manual;
    if (_mode == _OrderMode.manual) _loadProducts('');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Product loading (manual mode) ─────────────────────────────────────────

  Future<void> _loadProducts(String query, {int page = 1}) async {
    if (page == 1) setState(() { _products = []; _productsLoading = true; });
    try {
      final uc = context.read<SearchProductsUseCase>();
      final moreUc = context.read<HasMoreProductsUseCase>();
      final result = await uc(query, page: page);
      final moreResult = await moreUc(query, page);
      if (!mounted) return;
      result.fold(
        (_) => setState(() => _productsLoading = false),
        (list) {
          final hasMore = moreResult.fold((_) => false, (v) => v);
          setState(() {
            _products = page == 1 ? list : [..._products, ...list];
            _productsLoading = false;
            _productsHasMore = hasMore;
            _productsPage = page;
          });
        },
      );
    } catch (_) {
      if (mounted) setState(() => _productsLoading = false);
    }
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _loadProducts(q));
  }

  void _loadMore() {
    if (!_productsHasMore || _productsLoading) return;
    _loadProducts(_searchCtrl.text, page: _productsPage + 1);
  }

  // ── Quantity controls ─────────────────────────────────────────────────────

  void _inc(int id) => setState(() => _quantities[id] = (_quantities[id] ?? 0) + 1);

  void _dec(int id) {
    final cur = _quantities[id] ?? 0;
    if (cur <= 1) {
      setState(() => _quantities.remove(id));
    } else {
      setState(() => _quantities[id] = cur - 1);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _submit() {
    final notes = _notesCtrl.text.trim();
    if (_mode == _OrderMode.fromRecommendation) {
      context.read<OperatorOrderBloc>().add(
            OperatorOrderCreateFromRecommendation(
              phone: widget.phone,
              operatorRecommendationId: widget.recommendationId!,
              customerNotes: notes.isEmpty ? null : notes,
            ),
          );
    } else {
      if (_quantities.isEmpty) return;
      final items = _quantities.entries
          .map((e) => OrderItemInput(productId: e.key, quantity: e.value))
          .toList();
      context.read<OperatorOrderBloc>().add(
            OperatorOrderCreateManual(
              phone: widget.phone,
              items: items,
              leadId: widget.leadId,
              customerNotes: notes.isEmpty ? null : notes,
            ),
          );
    }
  }

  bool get _canSubmit {
    if (_mode == _OrderMode.fromRecommendation) return true;
    return _quantities.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OperatorOrderBloc, OperatorOrderState>(
      listenWhen: (_, s) => s is OperatorOrderCreated || s is OperatorOrderError,
      listener: (ctx, state) {
        if (state is OperatorOrderCreated) {
          Navigator.of(ctx).pop();
          _showSuccess(ctx, state.order);
        } else if (state is OperatorOrderError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ));
        }
      },
      builder: (ctx, state) {
        final isCreating = state is OperatorOrderCreating;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogHeader(onClose: () => Navigator.of(ctx).pop()),
                if (widget.recommendationId == null) _ModeToggle(mode: _mode, onChanged: (m) {
                  setState(() { _mode = m; _quantities.clear(); });
                  if (m == _OrderMode.manual && _products.isEmpty) _loadProducts('');
                }),
                Flexible(child: _body()),
                _Footer(
                  phone: widget.phone,
                  notesCtrl: _notesCtrl,
                  isCreating: isCreating,
                  canSubmit: _canSubmit,
                  selectedCount: _mode == _OrderMode.manual ? _quantities.length : null,
                  onSubmit: _submit,
                  onCancel: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _body() {
    if (_mode == _OrderMode.fromRecommendation) return _RecommendationBody(widget.recommendationId!);
    return _ManualBody(
      products: _products,
      loading: _productsLoading,
      hasMore: _productsHasMore,
      quantities: _quantities,
      searchCtrl: _searchCtrl,
      onSearch: _onSearch,
      onInc: _inc,
      onDec: _dec,
      onLoadMore: _loadMore,
    );
  }

  void _showSuccess(BuildContext ctx, OperatorOrderEntity order) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Buyurtma yaratildi!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              order.orderNumber,
              style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Jami: ${_fmt(order.totalAmount.toInt())} so\'m',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mijoz "Buyurtmalarim" bo\'limida ko\'radi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Yaxshi'),
          ),
        ],
      ),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _DialogHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buyurtma yaratish',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text('Mijoz nomidan buyurtma',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _OrderMode mode;
  final ValueChanged<_OrderMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(child: _Tab(label: 'Tavsiyadan', active: mode == _OrderMode.fromRecommendation,
              onTap: () => onChanged(_OrderMode.fromRecommendation))),
          const SizedBox(width: 8),
          Expanded(child: _Tab(label: 'Qo\'lda tanlash', active: mode == _OrderMode.manual,
              onTap: () => onChanged(_OrderMode.manual))),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _RecommendationBody extends StatelessWidget {
  final int recommendationId;
  const _RecommendationBody(this.recommendationId);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.recommend_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tavsiyadan yaratiladi',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('Tavsiya #$recommendationId dagi mahsulotlar (har biri 1 dona)',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualBody extends StatelessWidget {
  final List<ChatProductEntity> products;
  final bool loading;
  final bool hasMore;
  final Map<int, int> quantities;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final ValueChanged<int> onInc;
  final ValueChanged<int> onDec;
  final VoidCallback onLoadMore;

  const _ManualBody({
    required this.products,
    required this.loading,
    required this.hasMore,
    required this.quantities,
    required this.searchCtrl,
    required this.onSearch,
    required this.onInc,
    required this.onDec,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Mahsulot qidirish...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: loading && products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Mahsulotlar topilmadi',
                              style: TextStyle(color: Color(0xFF94A3B8))),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n is ScrollEndNotification &&
                              n.metrics.pixels >= n.metrics.maxScrollExtent - 80) {
                            onLoadMore();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: products.length + (hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == products.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            }
                            final p = products[i];
                            final qty = quantities[p.id] ?? 0;
                            return _ProductRow(
                              product: p,
                              quantity: qty,
                              onInc: () => onInc(p.id),
                              onDec: () => onDec(p.id),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final ChatProductEntity product;
  final int quantity;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _ProductRow({
    required this.product,
    required this.quantity,
    required this.onInc,
    required this.onDec,
  });

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : Colors.white,
        border: Border.all(
          color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: product.image.isNotEmpty
                ? Image.network(
                    ApiConstants.resolveMediaUrl(product.image),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, s) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Text('${_fmt(product.finalPrice)} so\'m',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Quantity stepper
          Row(
            children: [
              _StepBtn(icon: Icons.remove_rounded, onTap: quantity > 0 ? onDec : null),
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  quantity == 0 ? '' : '$quantity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: quantity > 0 ? AppColors.primary : Colors.transparent,
                  ),
                ),
              ),
              _StepBtn(icon: Icons.add_rounded, onTap: onInc, primary: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 40,
        height: 40,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.medication_outlined, size: 20, color: Color(0xFFCBD5E1)),
      );

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  const _StepBtn({required this.icon, this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFFF1F5F9)
              : primary
                  ? AppColors.primary
                  : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap == null
                ? const Color(0xFFCBD5E1)
                : primary
                    ? Colors.white
                    : const Color(0xFF475569)),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final String phone;
  final TextEditingController notesCtrl;
  final bool isCreating;
  final bool canSubmit;
  final int? selectedCount;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _Footer({
    required this.phone,
    required this.notesCtrl,
    required this.isCreating,
    required this.canSubmit,
    this.selectedCount,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phone chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(phone,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                const Spacer(),
                const Text('Buyurtma kimga', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Izoh (ixtiyoriy)',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isCreating ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Bekor qilish'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: (isCreating || !canSubmit) ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          selectedCount != null && selectedCount! > 0
                              ? 'Buyurtma ($selectedCount mahsulot)'
                              : 'Buyurtma berish',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
