class BookContent {
  final String id;
  final String title;
  final String subtitle;
  final String author;
  final List<BookSection> sections;

  const BookContent({
    required this.id,
    this.title = 'Untitled',
    this.subtitle = '',
    this.author = '',
    this.sections = const [],
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

  const BookChapter({required this.number, this.content = ''});
}
