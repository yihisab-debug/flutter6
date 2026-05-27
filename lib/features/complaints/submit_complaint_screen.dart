import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../models/complaint_model.dart';
import '../../models/ride_model.dart';
import '../../repositories/complaint_repository.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key, required this.ride});

  final RideModel ride;

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final _reasonCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _repo = ComplaintRepository();
  String? _selectedReason;
  bool _submitting = false;

  static const _reasons = [
    'Грубое поведение',
    'Опоздание',
    'Не приехал/не явился',
    'Небезопасное вождение',
    'Завышенная стоимость',
    'Проблема с оплатой',
    'Грязный салон',
    'Другое',
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final reason = _selectedReason == 'Другое'
        ? _reasonCtrl.text.trim()
        : _selectedReason;

    if (reason == null || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите или укажите причину'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final description = _descriptionCtrl.text.trim();
    if (description.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Опишите проблему подробнее (минимум 10 символов)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    String againstUserId;
    String againstUserName;
    if (user.isPassenger) {
      againstUserId = widget.ride.driverId;
      againstUserName = widget.ride.driverName;
    } else {
      againstUserId = widget.ride.passengerId;
      againstUserName = widget.ride.passengerName;
    }

    try {
      await _repo.createComplaint(
        ComplaintModel(
          id: '',
          rideId: widget.ride.id,
          fromUserId: user.id,
          fromUserName: user.name,
          fromUserRole: user.role,
          againstUserId: againstUserId,
          againstUserName: againstUserName,
          reason: reason,
          description: description,
          status: ComplaintStatus.pending,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Жалоба отправлена. Администратор её рассмотрит и свяжется с вами.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подать жалобу')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trip_origin,
                        size: 16, color: Colors.green[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(widget.ride.fromAddress,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(widget.ride.toAddress,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                if (widget.ride.driverName.isNotEmpty &&
                    context.read<AuthProvider>().user?.isPassenger ==
                        true) ...[
                  const SizedBox(height: 6),
                  Text('Водитель: ${widget.ride.driverName}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[700])),
                ],
                if (widget.ride.passengerName.isNotEmpty &&
                    context.read<AuthProvider>().user?.isDriver == true) ...[
                  const SizedBox(height: 6),
                  Text('Пассажир: ${widget.ride.passengerName}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[700])),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Причина жалобы',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reasons.map((r) {
              final selected = _selectedReason == r;
              return ChoiceChip(
                label: Text(r),
                selected: selected,
                onSelected: (_) => setState(() => _selectedReason = r),
              );
            }).toList(),
          ),
          if (_selectedReason == 'Другое') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Укажите причину',
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Подробное описание',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText:
                  'Опишите, что произошло. Чем подробнее — тем быстрее администратор сможет помочь.',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Отправить жалобу'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
