class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String? coverPath;
  final String pdfPath;
  final int totalPages;
  final int? publishedYear;
  final bool isActive;
  final DateTime? createdAt;

  const Book({
    required this.id, required this.title, required this.author,
    this.description, this.coverPath, required this.pdfPath,
    required this.totalPages, this.publishedYear, required this.isActive,
    this.createdAt,
  });

  factory Book.fromMap(Map<String, dynamic> map) => Book(
    id: map['id'] as String,
    title: map['title'] as String? ?? 'Untitled',
    author: map['author'] as String? ?? 'Unknown author',
    description: map['description'] as String?,
    coverPath: map['cover_path'] as String?,
    pdfPath: map['pdf_path'] as String? ?? '',
    totalPages: (map['total_pages'] as num?)?.toInt() ?? 0,
    publishedYear: (map['published_year'] as num?)?.toInt(),
    isActive: map['is_active'] as bool? ?? true,
    createdAt: map['created_at'] == null ? null : DateTime.tryParse(map['created_at'] as String),
  );
}
