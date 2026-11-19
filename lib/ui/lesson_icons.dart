import 'package:flutter/material.dart';

/// Symbole der Inseln (Name aus der Lektions-JSON → Icon).
const lessonIcons = <String, IconData>{
  'chat': Icons.chat_bubble_rounded,
  'inventory': Icons.inventory_2_rounded,
  'category': Icons.category_rounded,
  'calculate': Icons.calculate_rounded,
  'swap': Icons.swap_horiz_rounded,
  'text': Icons.text_fields_rounded,
  'auto_fix': Icons.auto_fix_high_rounded,
  'format_quote': Icons.format_quote_rounded,
  'toggle': Icons.toggle_on_rounded,
  'call_split': Icons.call_split_rounded,
  'loop': Icons.loop_rounded,
  'repeat': Icons.repeat_rounded,
  'list': Icons.format_list_bulleted_rounded,
  'playlist_add': Icons.playlist_add_rounded,
  'lock': Icons.lock_outline_rounded,
  'bubble_chart': Icons.bubble_chart_rounded,
  'menu_book': Icons.menu_book_rounded,
  'functions': Icons.functions_rounded,
  'bolt': Icons.bolt_rounded,
  'skip_next': Icons.skip_next_rounded,
  'star': Icons.star_rounded,
};

IconData lessonIcon(String name) => lessonIcons[name] ?? Icons.star_rounded;
