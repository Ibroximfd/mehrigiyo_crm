import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../operator_chat/domain/usecases/chat_usecases.dart';
import '../../domain/entities/lead_entity.dart';
import '../bloc/leads_bloc.dart';
import '../widgets/lead_card.dart';
import '../widgets/create_lead_dialog.dart';

class MyLeadsPage extends StatelessWidget {
  const MyLeadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Yangi mijoz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: BlocListener<LeadsBloc, LeadsState>(
        listenWhen: (_, s) => s is LeadCreateError,
        listener: (ctx, state) {
          if (state is LeadCreateError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ));
          }
        },
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => context.read<LeadsBloc>().add(const LeadsLoadRequested()),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mening Leadlarim',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Sizga biriktirilgan mijozlar',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
              BlocBuilder<LeadsBloc, LeadsState>(
                builder: (ctx, state) {
                  if (state is LeadsLoading) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    );
                  }
                  if (state is LeadsError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(state.message, style: const TextStyle(color: Color(0xFF64748B))),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => ctx.read<LeadsBloc>().add(const LeadsLoadRequested()),
                              child: const Text('Qayta yuklash'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final leads = state is LeadsLoaded
                      ? state.leads
                      : state is LeadCreating
                          ? state.leads
                          : state is LeadCreated
                              ? state.leads
                              : state is LeadCreateError
                                  ? state.leads
                                  : <dynamic>[];

                  if (leads.isEmpty && state is! LeadsLoading) {
                    return const SliverFillRemaining(child: _EmptyView());
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          if (i == leads.length) {
                            final loaded = state is LeadsLoaded && state.hasMore;
                            return loaded
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: OutlinedButton(
                                        onPressed: () => ctx.read<LeadsBloc>().add(const LeadsLoadMore()),
                                        child: const Text('Ko\'proq'),
                                      ),
                                    ),
                                  )
                                : const SizedBox(height: 80);
                          }
                          final lead = leads[i] as LeadEntity;
                          return LeadCard(
                            lead: lead,
                            onTap: () => ctx.push(RouteNames.sellerLeadDetail(lead.id)),
                            onChatTap: () => _openChat(ctx, lead),
                          );
                        },
                        childCount: leads.length + 1,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(BuildContext context, LeadEntity lead) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
    final result = await GetIt.I<CreateChatRoomUseCase>()(phone: lead.phone, leadId: lead.id);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(f.message),
        backgroundColor: AppColors.error,
      )),
      (room) => context.push(
        RouteNames.sellerChatRoom(room.id),
        extra: {'name': room.participantName, 'phone': room.participantPhone, 'leadId': lead.id},
      ),
    );
  }

  void _showCreate(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LeadsBloc>(),
        child: const CreateLeadDialog(),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Color(0xFF94A3B8)),
          SizedBox(height: 16),
          Text(
            'Lead yo\'q',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Yangi mijoz qo\'shish uchun pastdagi + tugmasini bosing',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
