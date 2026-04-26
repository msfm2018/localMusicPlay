enum MediaType { audio, video }

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