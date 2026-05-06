enum MediaType { audio, video,unknown }

class MediaItem {
  final String name;
  final String path;
  final MediaType type;

  MediaItem({
    required this.name,
    required this.path,
    required this.type,
  });
}