"""
Pau EPUB Converter — Convert EPUB ebooks into Pau book format.

Usage:
    python3 epub2pau.py my_book.epub --title "My Book" --author "Me" > my_book.json
"""
import json, sys, os, re
from ebooklib import epub
from bs4 import BeautifulSoup

def extract_text_from_html(html: str) -> str:
    soup = BeautifulSoup(html, 'html.parser')
    for tag in soup(['script', 'style', 'nav']):
        tag.decompose()
    text = soup.get_text(separator='\n')
    lines = [l.strip() for l in text.split('\n') if l.strip()]
    return '\n'.join(lines)

def convert_epub(epub_path: str, title: str = None, author: str = None) -> dict:
    book = epub.read_epub(epub_path)

    # Metadata
    meta_title = title or str(book.get_metadata('DC', 'title')[0][0]) if book.get_metadata('DC', 'title') else 'Untitled'
    meta_author = author or (str(book.get_metadata('DC', 'creator')[0][0]) if book.get_metadata('DC', 'creator') else '')

    result = {
        'id': os.path.basename(epub_path).replace('.epub', '').lower().replace(' ', '_'),
        'title': meta_title,
        'author': meta_author,
        'subtitle': f'by {meta_author}' if meta_author else '',
        'sections': [],
    }

    chapter_num = 0
    for item in book.get_items():
        if item.get_type() == 9:  # ITEM_DOCUMENT
            html = item.get_content().decode('utf-8', errors='ignore')
            text = extract_text_from_html(html)
            if not text.strip():
                continue

            chapter_num += 1
            # Use first line as section title
            lines = text.split('\n')
            title_line = lines[0][:80] if lines[0] else f'Chapter {chapter_num}'
            content = '\n'.join(lines[1:]) if len(lines) > 1 else ''

            result['sections'].append({
                'title': title_line,
                'chapters': [{
                    'number': 1,
                    'content': content or title_line
                }]
            })

    return result

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Convert EPUB to Pau book format')
    parser.add_argument('input', help='EPUB file path')
    parser.add_argument('--title', '-t', help='Book title (overrides metadata)')
    parser.add_argument('--author', '-a', help='Author (overrides metadata)')
    args = parser.parse_args()

    data = convert_epub(args.input, args.title, args.author)
    print(json.dumps(data, indent=2, ensure_ascii=False))
