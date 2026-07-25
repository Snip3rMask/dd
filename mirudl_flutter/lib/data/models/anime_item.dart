class AnimeItem {
  final String id;
  final String title;
  final String thumbnail;
  final String rating;
  final String url;
  final String type;
  final String year;
  final String status;
  final int episodes;

  const AnimeItem({
    required this.id,
    required this.title,
    this.thumbnail = '',
    this.rating = '',
    this.url = '',
    this.type = '',
    this.year = '',
    this.status = '',
    this.episodes = 0,
  });

  factory AnimeItem.fromJson(Map<String, dynamic> json) {
    return AnimeItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown',
      thumbnail: json['thumbnail']?.toString() ?? '',
      rating: json['rating']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      episodes: json['episodes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnail': thumbnail,
        'rating': rating,
        'url': url,
        'type': type,
        'year': year,
        'status': status,
        'episodes': episodes,
      };
}
