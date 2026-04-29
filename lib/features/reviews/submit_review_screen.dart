import 'package:flutter/material.dart';
import '../../models/review_model.dart';
import '../../models/ride_model.dart';
import '../../repositories/review_repository.dart';
import 'rating_stars.dart';

class SubmitReviewScreen extends StatefulWidget {
  final RideModel ride;
  final String fromUserId;
  final String toUserId;
  final String toUserName;
  final String role;

  const SubmitReviewScreen({
    super.key,
    required this.ride,
    required this.fromUserId,
    required this.toUserId,
    required this.toUserName,
    required this.role,
  });

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  final _reviewRepo = ReviewRepository();
  final _commentCtrl = TextEditingController();

  int _rating = 5;
  bool _busy = false;
  bool _initializing = true;
  late RideModel _ride;

  bool get _isFromPassenger => widget.role == ReviewRole.passengerToDriver;

  bool get _hasExisting =>
      _isFromPassenger ? _ride.hasPassengerReview : _ride.hasDriverReview;

  bool get _editAllowed => !_hasExisting ||
      (_isFromPassenger
          ? _ride.isPassengerReviewEditable
          : _ride.isDriverReviewEditable);

  bool get _rideEligible => _ride.status == RideStatus.completed;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    _loadFresh();
  }

  Future<void> _loadFresh() async {
    try {
      final fresh = await _reviewRepo.reloadRide(widget.ride.id);
      if (!mounted) return;
      setState(() {
        _ride = fresh;
        if (_isFromPassenger && fresh.hasPassengerReview) {
          _rating = fresh.passengerRating;
          _commentCtrl.text = fresh.passengerComment;
        } else if (!_isFromPassenger && fresh.hasDriverReview) {
          _rating = fresh.driverRating;
          _commentCtrl.text = fresh.driverComment;
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_rideEligible) {
      _toast('Отзыв доступен только после завершения поездки');
      return;
    }
    if (_hasExisting && !_editAllowed) {
      _toast('Время на редактирование истекло');
      return;
    }

    setState(() => _busy = true);

    try {
      if (_isFromPassenger) {
        await _reviewRepo.savePassengerReview(
          ride: _ride,
          rating: _rating,
          comment: _commentCtrl.text.trim(),
        );
      } else {
        await _reviewRepo.saveDriverReview(
          ride: _ride,
          rating: _rating,
          comment: _commentCtrl.text.trim(),
        );
      }

      if (!mounted) return;
      _toast(_hasExisting ? 'Отзыв обновлён' : 'Спасибо за отзыв!');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _toast(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canEdit = _editAllowed;
    final isEditing = _hasExisting;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать отзыв' : 'Оценить поездку'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Оцените: ${widget.toUserName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.ride.fromAddress} → ${widget.ride.toAddress}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: RatingStars(
                value: _rating.toDouble(),
                size: 48,
                onChanged: canEdit
                    ? (v) => setState(() => _rating = v)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _ratingLabel(_rating),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentCtrl,
              enabled: canEdit,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Комментарий (необязательно)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            if (isEditing && !canEdit)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Время на редактирование (10 минут) истекло.\n'
                  'Изменить отзыв больше нельзя.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            if (isEditing && canEdit)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Вы редактируете отзыв. После 10 минут с момента '
                  'создания изменить его будет нельзя.',
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: (_busy || !canEdit) ? null : _submit,
              child: _busy
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(
                      isEditing ? 'Сохранить изменения' : 'Отправить',
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Ужасно';
      case 2: return 'Плохо';
      case 3: return 'Нормально';
      case 4: return 'Хорошо';
      case 5: return 'Отлично';
      default: return '';
    }
  }
}
