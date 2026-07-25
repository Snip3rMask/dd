class VideoSource {
  final String quality;
  final String url;
  final String language;
  final String server;
  final String source;
  final String subtitleUrl;

  const VideoSource({
    required this.quality,
    required this.url,
    this.language = 'jpn',
    this.server = 'AniDB',
    this.source = 'primary',
    this.subtitleUrl = '',
  });

  factory VideoSource.fromJson(Map<String, dynamic> json) {
    return VideoSource(
      quality: json['quality']?.toString() ?? 'Auto',
      url: json['url']?.toString() ?? '',
      language: json['language']?.toString() ?? 'jpn',
      server: json['server']?.toString() ?? 'AniDB',
      source: json['source']?.toString() ?? 'primary',
      subtitleUrl: json['subtitle_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'quality': quality,
        'url': url,
        'language': language,
        'server': server,
        'source': source,
        'subtitle_url': subtitleUrl,
      };
}
