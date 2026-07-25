class DownloadEntry {
  final String uri;
  final String title;
  final String parent;
  final int size;
  final int completedAt;

  const DownloadEntry({
    required this.uri,
    required this.title,
    this.parent = '',
    this.size = 0,
    this.completedAt = 0,
  });

  String get key => uri.isNotEmpty ? uri : title;

  String get parentName =>
      parent.isNotEmpty ? parent : 'AniDB';

  factory DownloadEntry.fromJson(Map<String, dynamic> json) {
    return DownloadEntry(
      uri: json['uri']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      parent: json['parent']?.toString() ?? '',
      size: json['size'] as int? ?? 0,
      completedAt: json['completed_at'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'uri': uri,
        'title': title,
        'parent': parent,
        'size': size,
        'completed_at': completedAt,
      };
}
