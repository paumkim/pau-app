class BookContent {
  final String id;
  final String title;
  final String subtitle;
  final String author;
  final List<BookSection> sections;

  BookContent({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.author = '',
    required this.sections,
  });
}

class BookSection {
  final String title;
  final List<BookChapter> chapters;

  BookSection({required this.title, required this.chapters});
}

class BookChapter {
  final int number;
  final String content;

  BookChapter({required this.number, this.content = ''});
}
