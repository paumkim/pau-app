import 'package:flutter/material.dart';

/// Pre-built categorized Zomi phrases for quick access.
/// Customer doesn't need to type — just tap and get translations.
class Phrasebook {
  const Phrasebook._();

  static final List<_PhraseCategory> categories = [
    _PhraseCategory('Greetings', Icons.waving_hand, [
      _Phrase('Hello', 'Huai na?'),
      _Phrase('Good morning', 'Nophawkho na diam?'),
      _Phrase('Good afternoon', 'Nonsutna hoih'),
      _Phrase('Good evening', 'Nophila hoih'),
      _Phrase('How are you?', 'Na diam?'),
      _Phrase('I am fine', 'Ka dam'),
      _Phrase('Thank you', 'Ka lawm'),
      _Phrase('Goodbye', 'Na kiteh hen'),
    ]),
    _PhraseCategory('Emergencies', Icons.warning, [
      _Phrase('Help!', 'Ka ma!'),
      _Phrase('I need a doctor', 'Ka damna sia ka ma'),
      _Phrase('Where is the hospital?', 'Damna in ko ah om?'),
      _Phrase('Call the police', 'Police koih'),
      _Phrase('I am lost', 'Ka mang'),
      _Phrase('It hurts here', 'Hih ah na sak'),
    ]),
    _PhraseCategory('Shopping', Icons.shopping_bag, [
      _Phrase('How much?', 'Bang zat?'),
      _Phrase('Too expensive', 'A man lian'),
      _Phrase('Smaller size', 'A nel nuam'),
      _Phrase('I\'ll take this', 'Hih ka la'),
      _Phrase('Do you accept card?', 'Card na sang a?'),
    ]),
    _PhraseCategory('Food', Icons.restaurant, [
      _Phrase('I am hungry', 'Ka gil'),
      _Phrase('The menu, please', 'Menu ka en nuam'),
      _Phrase('Delicious', 'A hoih mah'),
      _Phrase('Water please', 'Tui ka deih'),
      _Phrase('The bill, please', 'Bill ka nuam'),
    ]),
    _PhraseCategory('Family', Icons.family_restroom, [
      _Phrase('My mother', 'Ka nu'),
      _Phrase('My father', 'Ka pa'),
      _Phrase('My sibling', 'Ka sang'),
      _Phrase('My child', 'Ka na'),
      _Phrase('My husband/wife', 'Ka pasal/zawl'),
    ]),
    _PhraseCategory('Time', Icons.schedule, [
      _Phrase('What time?', 'Bangsan?'),
      _Phrase('Today', 'Tu ni'),
      _Phrase('Tomorrow', 'Khat ni'),
      _Phrase('Yesterday', 'Zing ni'),
      _Phrase('Later', 'Nuai'),
      _Phrase('Now', 'Tuni'),
    ]),
  ];

  static List<_Phrase> get all {
    return categories.expand((c) => c.phrases).toList();
  }
}

class _PhraseCategory {
  final String name;
  final IconData icon;
  final List<_Phrase> phrases;
  const _PhraseCategory(this.name, this.icon, this.phrases);
}

class _Phrase {
  final String english;
  final String zomi;
  const _Phrase(this.english, this.zomi);
}
