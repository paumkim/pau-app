"""
Pau Book Builder — Convert raw text into Pau book format.

Usage:
    python3 build_book.py input.txt --title "My Book" --author "Me" > my_book.json

Input format:
    Lines starting with # are section titles (e.g., # Chapter 1)
    Lines starting with ## are chapter numbers (e.g., ## 1)
    All other lines are content.

Example input.txt:
    # Genesis
    ## 1
    In the beginning God created...
    ## 2
    Thus the heavens and the earth...
    # Exodus
    ## 1
    Now these are the names...
"""
import json, sys, re

def parse_text(text: str) -> dict:
    lines = text.strip().split('\n')
    book = {"sections": []}
    current_section = None
    current_chapter = None

    for line in lines:
        line = line.rstrip()
        if line.startswith('# ') and not line.startswith('## '):
            title = line[2:].strip()
            current_section = {"title": title, "chapters": []}
            book["sections"].append(current_section)
            current_chapter = None
        elif line.startswith('## '):
            num = int(line[3:].strip())
            current_chapter = {"number": num, "content": ""}
            if current_section is not None:
                current_section["chapters"].append(current_chapter)
        elif current_chapter is not None and line.strip():
            if current_chapter["content"]:
                current_chapter["content"] += '\n' + line
            else:
                current_chapter["content"] = line

    return book


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Build Pau book format')
    parser.add_argument('input', help='Input text file')
    parser.add_argument('--title', '-t', default='Untitled', help='Book title')
    parser.add_argument('--author', '-a', default='', help='Author')
    parser.add_argument('--id', '-i', default=None, help='Book ID')
    args = parser.parse_args()

    with open(args.input, 'r', encoding='utf-8') as f:
        text = f.read()

    data = parse_text(text)
    data['id'] = args.id or args.title.lower().replace(' ', '_')
    data['title'] = args.title
    data['author'] = args.author
    data['subtitle'] = f'by {args.author}' if args.author else ''

    print(json.dumps(data, indent=2, ensure_ascii=False))
