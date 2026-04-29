import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../models/review_model.dart';
import '../../models/ride_model.dart';
import '../../repositories/review_repository.dart';
import 'rating_stars.dart';
import 'submit_review_screen.dart';

class RideReviewsScreen extends StatefulWidget {
  final RideModel ride;

  const RideReviewsScreen({super.key, required this.ride});

  @override
  State<RideReviewsScreen> createState() => _RideReviewsScreenState();
}

class _RideReviewsScreenState extends State<RideReviewsScreen> {
  final _reviewRepo = ReviewRepository();

  bool _loading = true;
  late RideModel _ride;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fresh = await _reviewRepo.reloadRide(widget.ride.id);
      if (!mounted) return;
      setState(() {
        _ride = fresh;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }

  bool get _meIsDriver => context.read<AuthProvider>().user!.isDriver;

  String _otherUserId() =>
      _meIsDriver ? _ride.passengerId : _ride.driverId;

  String _otherUserName() =>
      _meIsDriver ? _ride.passengerName : _ride.driverName;

  String _myRoleForReview() => _meIsDriver
      ? ReviewRole.driverToPassenger
      : ReviewRole.passengerToDriver;

  bool get _hasMyReview =>
      _meIsDriver ? _ride.hasDriverReview : _ride.hasPassengerReview;

  bool get _hasReviewAboutMe =>
      _meIsDriver ? _ride.hasPassengerReview : _ride.hasDriverReview;

  int get _myRating =>
      _meIsDriver ? _ride.driverRating : _ride.passengerRating;

  String get _myComment =>
      _meIsDriver ? _ride.driverComment : _ride.passengerComment;

  DateTime? get _myReviewDate =>
      _meIsDriver ? _ride.driverReviewDate : _ride.passengerReviewDate;

  bool get _myReviewEditable => _meIsDriver
      ? _ride.isDriverReviewEditable
      : _ride.isPassengerReviewEditable;

  int get _otherRating =>
      _meIsDriver ? _ride.passengerRating : _ride.driverRating;

  String get _otherComment =>
      _meIsDriver ? _ride.passengerComment : _ride.driverComment;

  DateTime? get _otherReviewDate =>
      _meIsDriver ? _ride.passengerReviewDate : _ride.driverReviewDate;

  Future<void> _openSubmitForm() async {
    final me = context.read<AuthProvider>().user!;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SubmitReviewScreen(
          ride: _ride,
          fromUserId: me.id,
          toUserId: _otherUserId(),
          toUserName: _otherUserName(),
          role: _myRoleForReview(),
        ),
      ),
    );

    if (result == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отзывы по поездке'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildRideCard(),
                  const SizedBox(height: 16),
                  _buildMySection(),
                  const SizedBox(height: 16),
                  _buildOtherSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildRideCard() {
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_ride.fromAddress} → ${_ride.toAddress}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                Text(
                  '${_ride.price.toStringAsFixed(0)} ₸',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                if (_ride.createdAt != null)
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(_ride.createdAt!),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Мой отзыв',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_hasMyReview)
              _buildReviewBody(
                rating: _myRating,
                comment: _myComment,
                date: _myReviewDate,
                editable: _myReviewEditable,
                showEdit: true,
              )
            else
              _buildEmptyMine(),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Отзыв обо мне (${_otherUserName()})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_hasReviewAboutMe)
              _buildReviewBody(
                rating: _otherRating,
                comment: _otherComment,
                date: _otherReviewDate,
                editable: false,
                showEdit: false,
              )
            else
              _buildEmptyOther(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewBody({
    required int rating,
    required String comment,
    required DateTime? date,
    required bool editable,
    required bool showEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RatingStars(value: rating.toDouble(), size: 22),
            const SizedBox(width: 8),
            Text(
              rating.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (date != null)
              Text(
                DateFormat('dd.MM.yyyy HH:mm').format(date),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(comment),
          ),
        ],
        if (showEdit && editable) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Редактировать'),
              onPressed: _openSubmitForm,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyMine() {
    final eligible = _ride.status == RideStatus.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Вы пока не оставили отзыв',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.rate_review),
          label: const Text('Оставить отзыв'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
          onPressed: eligible ? _openSubmitForm : null,
        ),
        if (!eligible)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Отзыв доступен только после завершения поездки',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyOther() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.hourglass_empty, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_otherUserName().isEmpty ? "Вторая сторона" : _otherUserName()} '
                'пока не оставил отзыв',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Обновить страницу'),
          onPressed: _load,
        ),
      ],
    );
  }
}
