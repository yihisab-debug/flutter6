import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../repositories/review_repository.dart';
import 'rating_stars.dart';

class UserReviewsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final double averageRating;
  final int reviewsCount;

  const UserReviewsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.averageRating,
    required this.reviewsCount,
  });

  @override
  State<UserReviewsScreen> createState() => _UserReviewsScreenState();
}

class _UserReviewsScreenState extends State<UserReviewsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ReviewRepository();

  late final TabController _tab;

  String _sort = ReviewSortMode.dateDesc;
  String _filter = ReviewFilter.all;

  late Future<List<ReviewItem>> _aboutFuture;
  late Future<List<ReviewItem>> _myFuture;

  List<ReviewItem> _aboutReviews = const [];
  List<ReviewItem> _myReviews = const [];

  @override
  void initState() {
    super.initState();

    _tab = TabController(length: 2, vsync: this);

    _tab.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _reload();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _reload() {
    _aboutFuture = _repo.getReviewsForUser(
      widget.userId,
      sort: _sort,
      filter: _filter,
    );

    _aboutFuture.then((value) {
      if (mounted) {
        setState(() {
          _aboutReviews = value;
        });
      }
    });

    _myFuture = _repo.getReviewsByUser(
      widget.userId,
      sort: _sort,
      filter: _filter,
    );

    _myFuture.then((value) {
      if (mounted) {
        setState(() {
          _myReviews = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отзывы'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Обо мне'),
            Tab(text: 'Мои отзывы'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildControls(),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildList(_aboutFuture, isMyReviews: false),
                _buildList(_myFuture, isMyReviews: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isMyTab = _tab.index == 1;
    final list = isMyTab ? _myReviews : _aboutReviews;
    final count = list.length;
    final avg = count == 0
        ? 0.0
        : list.fold<int>(0, (a, r) => a + r.rating) / count;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.amber[50],
      child: Column(
        children: [
          Text(
            count == 0 ? '—' : avg.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          RatingStars(value: avg, size: 22),
          const SizedBox(height: 4),
          Text(
            'Всего отзывов: $count',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sort,
              isExpanded: true,
              style: const TextStyle(fontSize: 13, color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Сортировка',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: ReviewSortMode.dateDesc,
                  child: Text(
                    'Новые первыми',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: ReviewSortMode.dateAsc,
                  child: Text(
                    'Старые первыми',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: ReviewSortMode.ratingDesc,
                  child: Text(
                    'Высокие оценки',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: ReviewSortMode.ratingAsc,
                  child: Text(
                    'Низкие оценки',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;

                setState(() {
                  _sort = v;
                  _reload();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filter,
              isExpanded: true,
              style: const TextStyle(fontSize: 13, color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Фильтр',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: ReviewFilter.all,
                  child: Text('Все', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: ReviewFilter.positive,
                  child: Text(
                    'Положительные',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: ReviewFilter.negative,
                  child: Text(
                    'Отрицательные',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;

                setState(() {
                  _filter = v;
                  _reload();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    Future<List<ReviewItem>> future, {
    required bool isMyReviews,
  }) {
    return FutureBuilder<List<ReviewItem>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(child: Text('Ошибка: ${snap.error}'));
        }

        final reviews = snap.data ?? [];

        if (reviews.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                isMyReviews
                    ? 'Вы ещё не оставляли отзывов'
                    : 'Пока нет отзывов',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await future;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: reviews.length,
            itemBuilder: (_, i) =>
                _buildTile(reviews[i], isMyReviews: isMyReviews),
          ),
        );
      },
    );
  }

  Widget _buildTile(ReviewItem r, {required bool isMyReviews}) {
    final displayName = isMyReviews
        ? (r.toUserName.isNotEmpty ? r.toUserName : 'Пользователь')
        : (r.fromUserName.isNotEmpty ? r.fromUserName : 'Аноним');
    final initial = displayName.characters.first.toUpperCase();
    final caption = isMyReviews ? 'Кому: $displayName' : displayName;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.amber.shade100,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caption,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(r.createdAt),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RatingStars(value: r.rating.toDouble(), size: 18),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r.comment,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
