/// Simple domain model representing an artwork / project.
class ArtPiece {

  const ArtPiece({
    required this.id,
    required this.title,
    required this.author,
    required this.imagePath,
    required this.description,
  });
  final String id;
  final String title;
  final String author;
  final String imagePath; // For now we use local placeholder asset paths.
  final String description;

  static List<ArtPiece> dummy = List.generate(12, (i) => ArtPiece(
      id: 'art_$i',
      title: 'Concept Study ${i + 1}',
      author: 'Artist ${String.fromCharCode(65 + (i % 5))}',
      imagePath: 'assets/images/placeholder.png',
      description: 'Exploratory concept piece number ${i + 1}.',
    ));
}
