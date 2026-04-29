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

class _UserReviewsScreenState extends State<UserReviewsScreen> {
  final _repo = ReviewRepository();

  String _sort = ReviewSortMode.dateDesc;
  String _filter = ReviewFilter.all;
  late Future<List<ReviewItem>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repo.getReviewsForUser(
      widget.userId,
      sort: _sort,
      filter: _filter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Отзывы о ${widget.userName}')),
      body: Column(
        children: [
          _buildHeader(),
          _buildControls(),
          const Divider(height: 1),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.amber[50],
      child: Column(
        children: [
          Text(
            widget.averageRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          RatingStars(value: widget.averageRating, size: 22),
          const SizedBox(height: 4),
          Text(
            'Всего отзывов: ${widget.reviewsCount}',
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

  Widget _buildList() {
    return FutureBuilder<List<ReviewItem>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Ошибка: ${snap.error}'));
        }
        final reviews = snap.data ?? [];
        if (reviews.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Пока нет отзывов',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _future;
          },
          child: ListView.separated(
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _buildTile(reviews[i]),
          ),
        );
      },
    );
  }

  Widget _buildTile(ReviewItem r) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingStars(value: r.rating.toDouble(), size: 18),
              const Spacer(),
              Text(
                DateFormat('dd.MM.yyyy HH:mm').format(r.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r.comment),
          ],
        ],
      ),
    );
  }
}
