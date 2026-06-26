import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/operator_entity.dart';
import '../bloc/operators_bloc.dart';
import '../widgets/operator_card.dart';
import '../widgets/create_operator_dialog.dart';
import '../widgets/edit_operator_dialog.dart';

class OperatorsPage extends StatelessWidget {
  const OperatorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: const Color(0xFF0D6A55),
        onRefresh: () async =>
            context.read<OperatorsBloc>().add(const OperatorsLoadRequested()),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Operatorlar',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Filialingizdagi sotuvchilar',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _AddButton(onPressed: () => _showCreateDialog(context)),
                  ],
                ),
              ),
            ),
            BlocBuilder<OperatorsBloc, OperatorsState>(
              builder: (context, state) {
                if (state is OperatorsLoading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0D6A55)),
                    ),
                  );
                }
                if (state is OperatorsError) {
                  return SliverFillRemaining(
                    child: _ErrorView(
                      message: state.message,
                      onRetry: () => context
                          .read<OperatorsBloc>()
                          .add(const OperatorsLoadRequested()),
                    ),
                  );
                }
                if (state is OperatorsLoaded) {
                  if (state.operators.isEmpty) {
                    return const SliverFillRemaining(child: _EmptyView());
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          if (i == state.operators.length) {
                            return state.hasMore
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: TextButton.icon(
                                        onPressed: () => ctx
                                            .read<OperatorsBloc>()
                                            .add(const OperatorsLoadMore()),
                                        icon: const Icon(Icons.expand_more_rounded),
                                        label: const Text('Ko\'proq yuklash'),
                                      ),
                                    ),
                                  )
                                : const SizedBox(height: 12);
                          }
                          final op = state.operators[i];
                          return OperatorCard(
                            operator: op,
                            onEdit: () => _showEditDialog(context, op),
                          );
                        },
                        childCount: state.operators.length + 1,
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<OperatorsBloc>(),
        child: const CreateOperatorDialog(),
      ),
    );
  }

  void _showEditDialog(BuildContext context, OperatorEntity operator) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<OperatorsBloc>(),
        child: EditOperatorDialog(operator: operator),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Yangi'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 36, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Qayta yuklash'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4F0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 40,
              color: Color(0xFF0D6A55),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Operatorlar yo\'q',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Yangi operator qo\'shish uchun\n"Yangi" tugmasini bosing',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
