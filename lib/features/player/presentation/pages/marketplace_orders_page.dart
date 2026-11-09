import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_orders_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_orders_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/order_card.dart';

/// Player Marketplace Orders Page showing player's order history, active shipments, and order statuses.
class MarketplaceOrdersPage extends StatelessWidget {
  final MarketplaceOrdersCubit? cubit;

  const MarketplaceOrdersPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? sl<MarketplaceOrdersCubit>())..loadOrders(),
      child: const _MarketplaceOrdersView(),
    );
  }
}

class _MarketplaceOrdersView extends StatefulWidget {
  const _MarketplaceOrdersView();

  @override
  State<_MarketplaceOrdersView> createState() => _MarketplaceOrdersViewState();
}

class _MarketplaceOrdersViewState extends State<_MarketplaceOrdersView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<String> _tabs = const ['All Orders', 'Active', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final cubit = context.read<MarketplaceOrdersCubit>();
    switch (_tabController.index) {
      case 0:
        cubit.filterByStatus(null);
        break;
      case 1:
        cubit.filterByStatus(MarketplaceOrderStatus.inTransit);
        break;
      case 2:
        cubit.filterByStatus(MarketplaceOrderStatus.delivered);
        break;
      case 3:
        cubit.filterByStatus(MarketplaceOrderStatus.cancelled);
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Marketplace Orders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<MarketplaceOrdersCubit, MarketplaceOrdersState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state is MarketplaceOrdersLoading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (state is MarketplaceOrdersFailure) {
              return ErrorStateView(
                message: state.message,
                onRetry: () => context.read<MarketplaceOrdersCubit>().loadOrders(),
              );
            }

            if (state is MarketplaceOrdersLoaded) {
              final orders = state.filteredOrders;

              if (orders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 72,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No orders found',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          state.filterStatus != null
                              ? 'No orders matching the selected status.'
                              : 'You have not placed any marketplace orders yet.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: 'Explore Store',
                          onPressed: () {
                            context.go(AppRoutes.playerMarketplace);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context.read<MarketplaceOrdersCubit>().loadOrders(showLoading: false),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(
                      order: order,
                      onTap: () {
                        context.push(AppRoutes.playerMarketplaceOrderDetailsPath(order.id)).then((_) {
                          if (context.mounted) {
                            context.read<MarketplaceOrdersCubit>().loadOrders(showLoading: false);
                          }
                        });
                      },
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
