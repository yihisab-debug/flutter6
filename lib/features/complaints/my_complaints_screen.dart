import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../models/complaint_model.dart';
import '../../repositories/complaint_repository.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ComplaintRepository();
  late final TabController _tab;

  List<ComplaintModel> _myComplaints = [];
  List<ComplaintModel> _againstMe = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _repo.getComplaintsByUser(user.id),
        _repo.getComplaintsAgainstUser(user.id),
      ]);
      if (!mounted) return;
      setState(() {
        _myComplaints = results[0];
        _againstMe = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои жалобы'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'От меня (${_myComplaints.length})'),
            Tab(text: 'На меня (${_againstMe.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tab,
                  children: [
                    _ComplaintList(
                      items: _myComplaints,
                      onReload: _load,
                      isMine: true,
                    ),
                    _ComplaintList(
                      items: _againstMe,
                      onReload: _load,
                      isMine: false,
                    ),
                  ],
                ),
    );
  }
}

class _ComplaintList extends StatelessWidget {
  const _ComplaintList({
    required this.items,
    required this.onReload,
    required this.isMine,
  });

  final List<ComplaintModel> items;
  final VoidCallback onReload;

  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              isMine ? 'Вы пока не подавали жалоб' : 'На вас никто не жаловался',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ComplaintCard(
          complaint: items[i],
          isMine: isMine,
        ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint, required this.isMine});

  final ComplaintModel complaint;
  final bool isMine;

  Color _statusColor() {
    switch (complaint.status) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.rejected:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon() {
    switch (complaint.status) {
      case ComplaintStatus.pending:
        return Icons.hourglass_top;
      case ComplaintStatus.resolved:
        return Icons.check_circle;
      case ComplaintStatus.rejected:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _statusDescription() {
    if (isMine) {
      switch (complaint.status) {
        case ComplaintStatus.pending:
          return 'Ожидает рассмотрения администратором';
        case ComplaintStatus.resolved:
          return complaint.refundProcessed && complaint.refundAmount > 0
              ? 'Удовлетворена. Возвращено ${complaint.refundAmount.toStringAsFixed(0)} ₸'
              : 'Удовлетворена администратором';
        case ComplaintStatus.rejected:
          return 'Отклонена администратором';
        default:
          return '';
      }
    } else {
      switch (complaint.status) {
        case ComplaintStatus.pending:
          return 'На вас подана жалоба. Ожидает рассмотрения.';
        case ComplaintStatus.resolved:
          return complaint.refundProcessed && complaint.refundAmount > 0
              ? 'Жалоба удовлетворена. Пассажиру возвращено ${complaint.refundAmount.toStringAsFixed(0)} ₸'
              : 'Жалоба удовлетворена';
        case ComplaintStatus.rejected:
          return 'Жалоба отклонена администратором';
        default:
          return '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final dateStr = complaint.createdAt == null
        ? '—'
        : DateFormat('dd.MM.yyyy HH:mm').format(complaint.createdAt!);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(), color: color, size: 18),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ComplaintStatus.label(complaint.status),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(dateStr,
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              complaint.reason,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(complaint.description,
                style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isMine
                        ? 'На: ${complaint.againstUserName.isEmpty ? "—" : complaint.againstUserName}'
                        : 'От: ${complaint.fromUserName} (${complaint.fromUserRole == "passenger" ? "пассажир" : "водитель"})',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusDescription(),
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w600),
                  ),
                  if (complaint.adminResponse.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    const Divider(height: 12),
                    Text('Ответ администратора:',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700])),
                    const SizedBox(height: 4),
                    Text(complaint.adminResponse,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
