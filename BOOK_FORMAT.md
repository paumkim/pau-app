# Pau Book Format — Author Guide

Any book you write in this format works in the Pau reader engine.

## Structure

```
Book
├── Section (e.g. "Chapter 1", "Part 1", "Genesis")
│   ├── Chapter 1 (content: "verse 1...")
│   ├── Chapter 2
│   └── ...
└── Section 2
    └── ...
```

## JSON Format (easiest)

```json
{
  "id": "my_book",
  "title": "My Zomi Book",
  "subtitle": "A book for the Zomi people",
  "author": "Your Name",
  "sections": [
    {
      "title": "Section 1",
      "chapters": [
        {"number": 1, "content": "Full text of chapter 1 here..."},
        {"number": 2, "content": "Full text of chapter 2 here..."}
      ]
    }
  ]
}
```

## Adding to Pau

Place the JSON file in `assets/books/` and register it in the Library.
