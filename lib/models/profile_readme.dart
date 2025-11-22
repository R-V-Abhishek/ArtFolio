import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of content blocks that can be added to a profile README
enum ReadmeBlockType {
  header1,
  header2,
  header3,
  text,
  image,
  skillsTags,
  divider,
  quote,
  list,
}

/// A single content block in the README
class ReadmeBlock {
  ReadmeBlock({
    required this.id,
    required this.type,
    required this.content,
    this.imageUrl,
    this.order = 0,
    this.metadata,
  });

  factory ReadmeBlock.fromMap(Map<String, dynamic> map) => ReadmeBlock(
    id: map['id'] ?? '',
    type: ReadmeBlockType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => ReadmeBlockType.text,
    ),
    content: map['content'] ?? '',
    imageUrl: map['imageUrl'],
    order: map['order'] ?? 0,
    metadata: map['metadata'] != null
        ? Map<String, dynamic>.from(map['metadata'])
        : null,
  );
  final String id; // Unique identifier for the block
  final ReadmeBlockType type;
  final String content; // Text content or caption
  final String? imageUrl; // For image blocks
  final int order; // Display order
  final Map<String, dynamic>? metadata; // Additional properties

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'content': content,
    'imageUrl': imageUrl,
    'order': order,
    'metadata': metadata,
  };

  ReadmeBlock copyWith({
    String? id,
    ReadmeBlockType? type,
    String? content,
    String? imageUrl,
    int? order,
    Map<String, dynamic>? metadata,
  }) => ReadmeBlock(
    id: id ?? this.id,
    type: type ?? this.type,
    content: content ?? this.content,
    imageUrl: imageUrl ?? this.imageUrl,
    order: order ?? this.order,
    metadata: metadata ?? this.metadata,
  );
}

/// Complete profile README document
class ProfileReadme {
  ProfileReadme({
    required this.userId,
    required this.blocks,
    this.theme,
    this.lastUpdated,
  });

  factory ProfileReadme.fromMap(Map<String, dynamic> map) => ProfileReadme(
    userId: map['userId'] ?? '',
    blocks:
        (map['blocks'] as List<dynamic>?)
            ?.map((b) => ReadmeBlock.fromMap(b as Map<String, dynamic>))
            .toList() ??
        [],
    theme: map['theme'],
    lastUpdated: map['lastUpdated'] != null
        ? (map['lastUpdated'] as Timestamp).toDate()
        : null,
  );

  factory ProfileReadme.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data()! as Map<String, dynamic>;
    return ProfileReadme.fromMap(data);
  }

  /// Creates an empty README with default content
  factory ProfileReadme.defaultReadme(String userId) => ProfileReadme(
    userId: userId,
    blocks: [
      ReadmeBlock(id: '1', type: ReadmeBlockType.header1, content: 'About Me'),
      ReadmeBlock(
        id: '2',
        type: ReadmeBlockType.text,
        content:
            'Tell the world about yourself! Add your story, inspirations, and creative journey.',
        order: 1,
      ),
      ReadmeBlock(
        id: '3',
        type: ReadmeBlockType.header2,
        content: 'My Skills',
        order: 2,
      ),
      ReadmeBlock(
        id: '4',
        type: ReadmeBlockType.skillsTags,
        content: '',
        order: 3,
        metadata: {'tags': <String>[]},
      ),
    ],
    lastUpdated: DateTime.now(),
  );
  final String userId;
  final List<ReadmeBlock> blocks;
  final String? theme; // Theme/styling preferences
  final DateTime? lastUpdated;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'blocks': blocks.map((b) => b.toMap()).toList(),
    'theme': theme,
    'lastUpdated': lastUpdated != null
        ? Timestamp.fromDate(lastUpdated!)
        : FieldValue.serverTimestamp(),
  };

  ProfileReadme copyWith({
    String? userId,
    List<ReadmeBlock>? blocks,
    String? theme,
    DateTime? lastUpdated,
  }) => ProfileReadme(
    userId: userId ?? this.userId,
    blocks: blocks ?? this.blocks,
    theme: theme ?? this.theme,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  /// Get sorted blocks by order
  List<ReadmeBlock> get sortedBlocks {
    final sorted = List<ReadmeBlock>.from(blocks);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }
}
