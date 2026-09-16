/// Une annonce, telle que renvoyée par AnnouncementResource
/// (docs/PRODUCT_ARCHITECTURE.md §8).
class Announcement {
  final int id;
  final String title;
  final String body;
  final String category;
  final String? publishedAt;
  final String? authorName;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.publishedAt,
    this.authorName,
  });

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id:          j['id'] as int,
        title:       j['title'] as String,
        body:        j['body'] as String,
        category:    j['category'] as String? ?? 'info',
        publishedAt: j['published_at'] as String?,
        authorName:  j['author_name'] as String?,
      );
}
