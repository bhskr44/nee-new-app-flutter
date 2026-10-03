import '../widgets/app_empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet_model.dart';
import '../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _loadErrors = <String>{};
  int _balance = 0;
  bool _balanceLoading = true;

  List<PointTransactionModel> _transactions = [];
  bool _transactionsLoading = true;

  List<RewardModel> _rewards = [];
  bool _rewardsLoading = true;

  List<RewardRedemptionModel> _redemptions = [];
  bool _redemptionsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchBalance();
    _fetchTransactions();
    _fetchRewards();
    _fetchRedemptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _balanceLoading = true;
      _loadErrors.remove('balance');
    });
    try {
      final data = await apiService.getWalletBalance();
      if (!mounted) return;
      setState(() {
        _balance = data['points_balance'] ?? 0;
        _balanceLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _balanceLoading = false;
        _loadErrors.add('balance');
      });
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _transactionsLoading = true;
      _loadErrors.remove('transactions');
    });
    try {
      final data = await apiService.getPointsTransactions();
      if (!mounted) return;
      setState(() {
        _transactions =
            (data['data'] as List)
                .map((e) => PointTransactionModel.fromJson(e))
                .toList();
        _transactionsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _transactionsLoading = false;
        _loadErrors.add('transactions');
      });
    }
  }

  Future<void> _fetchRewards() async {
    setState(() {
      _rewardsLoading = true;
      _loadErrors.remove('rewards');
    });
    try {
      final data = await apiService.getRewards();
      if (!mounted) return;
      setState(() {
        _rewards = data.map((e) => RewardModel.fromJson(e)).toList();
        _rewardsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rewardsLoading = false;
        _loadErrors.add('rewards');
      });
    }
  }

  Future<void> _fetchRedemptions() async {
    setState(() {
      _redemptionsLoading = true;
      _loadErrors.remove('redemptions');
    });
    try {
      final data = await apiService.getMyRedemptions();
      if (!mounted) return;
      setState(() {
        _redemptions =
            (data['data'] as List)
                .map((e) => RewardRedemptionModel.fromJson(e))
                .toList();
        _redemptionsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _redemptionsLoading = false;
        _loadErrors.add('redemptions');
      });
    }
  }

  Future<void> _redeem(RewardModel reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Redeem Reward'),
            content: Text(
              'Redeem "${reward.name}" for ${reward.pointsRequired} points?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Redeem'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await apiService.redeemReward(reward.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Redemption requested! Track it under "My Redemptions".',
          ),
        ),
      );
      _fetchBalance();
      _fetchRewards();
      _fetchRedemptions();
      _tabController.animateTo(2);
    } catch (e) {
      if (!mounted) return;
      final message =
          e is DioException
              ? (e.response?.data?['message'] as String? ??
                  'Could not redeem reward.')
              : 'Could not redeem reward.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Points'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Passbook'),
            Tab(text: 'Redeem'),
            Tab(text: 'My Redemptions'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_loadErrors.contains('balance'))
            ListTile(
              title: const Text('Points balance unavailable'),
              trailing: IconButton(
                tooltip: 'Retry balance',
                icon: const Icon(Icons.refresh),
                onPressed: _fetchBalance,
              ),
            )
          else
            _BalanceCard(
              loading: _balanceLoading,
              balance: _balance,
              color: theme.colorScheme.primary,
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _loadErrors.contains('transactions')
                    ? AppEmptyState(
                      icon: Icons.refresh_rounded,
                      title: 'Could not load transactions',
                      message: 'Check your connection and try again.',
                      actionLabel: 'Try again',
                      onAction: _fetchTransactions,
                    )
                    : _PassbookTab(
                      loading: _transactionsLoading,
                      transactions: _transactions,
                      onRefresh: _fetchTransactions,
                    ),
                _loadErrors.contains('rewards')
                    ? AppEmptyState(
                      icon: Icons.refresh_rounded,
                      title: 'Could not load rewards',
                      message: 'Check your connection and try again.',
                      actionLabel: 'Try again',
                      onAction: _fetchRewards,
                    )
                    : _RedeemTab(
                      loading: _rewardsLoading,
                      rewards: _rewards,
                      balance: _balance,
                      onRefresh: _fetchRewards,
                      onRedeem: _redeem,
                    ),
                _loadErrors.contains('redemptions')
                    ? AppEmptyState(
                      icon: Icons.refresh_rounded,
                      title: 'Could not load redemptions',
                      message: 'Check your connection and try again.',
                      actionLabel: 'Try again',
                      onAction: _fetchRedemptions,
                    )
                    : _RedemptionsTab(
                      loading: _redemptionsLoading,
                      redemptions: _redemptions,
                      onRefresh: _fetchRedemptions,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final bool loading;
  final int balance;
  final Color color;

  const _BalanceCard({
    required this.loading,
    required this.balance,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Points Balance',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 2),
              loading
                  ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(
                    '$balance pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassbookTab extends StatelessWidget {
  final bool loading;
  final List<PointTransactionModel> transactions;
  final Future<void> Function() onRefresh;

  const _PassbookTab({
    required this.loading,
    required this.transactions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No points activity yet.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: transactions.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final tx = transactions[i];
          final color = tx.isEarn ? Colors.green[700] : Colors.red[700];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color!.withAlpha(25),
              child: Icon(
                tx.isEarn ? Icons.add : Icons.remove,
                color: color,
                size: 18,
              ),
            ),
            title: Text(
              tx.description ??
                  (tx.isEarn ? 'Points earned' : 'Points redeemed'),
              style: const TextStyle(fontSize: 13.5),
            ),
            subtitle: Text(
              _formatDate(tx.createdAt),
              style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
            ),
            trailing: Text(
              '${tx.isEarn ? '+' : ''}${tx.points}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }
}

class _RedeemTab extends StatelessWidget {
  final bool loading;
  final List<RewardModel> rewards;
  final int balance;
  final Future<void> Function() onRefresh;
  final void Function(RewardModel) onRedeem;

  const _RedeemTab({
    required this.loading,
    required this.rewards,
    required this.balance,
    required this.onRefresh,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (rewards.isEmpty) {
      return Center(
        child: Text(
          'No rewards available right now.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: rewards.length,
        itemBuilder: (_, i) {
          final reward = rewards[i];
          final canRedeem =
              reward.isAvailable && balance >= reward.pointsRequired;
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child:
                      reward.imageUrl != null
                          ? CachedNetworkImage(
                            imageUrl: reward.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder:
                                (_, _) => Container(color: Colors.grey[200]),
                            errorWidget:
                                (_, _, _) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.card_giftcard,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                          )
                          : Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.card_giftcard,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canRedeem ? () => onRedeem(reward) : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            textStyle: const TextStyle(fontSize: 11.5),
                          ),
                          child: Text(
                            !reward.isAvailable
                                ? 'Out of Stock'
                                : '${reward.pointsRequired} pts',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RedemptionsTab extends StatelessWidget {
  final bool loading;
  final List<RewardRedemptionModel> redemptions;
  final Future<void> Function() onRefresh;

  const _RedemptionsTab({
    required this.loading,
    required this.redemptions,
    required this.onRefresh,
  });

  static const _statusColors = {
    'pending': Color(0xFFF9A825),
    'approved': Color(0xFF1976D2),
    'rejected': Color(0xFFD32F2F),
    'fulfilled': Color(0xFF2E7D32),
  };

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (redemptions.isEmpty) {
      return Center(
        child: Text(
          'No redemptions yet.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: redemptions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r = redemptions[i];
          final color = _statusColors[r.status] ?? Colors.grey;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    r.rewardImageUrl != null
                        ? CachedNetworkImageProvider(r.rewardImageUrl!)
                        : null,
                child:
                    r.rewardImageUrl == null
                        ? const Icon(Icons.card_giftcard, color: Colors.grey)
                        : null,
              ),
              title: Text(
                r.rewardName,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${r.pointsSpent} pts',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  r.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
