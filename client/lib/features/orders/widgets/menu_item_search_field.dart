import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/database/models/menu_item_model.dart';
import '../../../core/database/repositories/menu_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';

/// Searchable dropdown of available menu items. Focusing it lists everything;
/// typing filters. Picking an item calls [onPicked] and clears the field, so
/// the same item can be picked again and again.
class MenuItemSearchField extends StatefulWidget {
  const MenuItemSearchField({super.key, required this.onPicked});

  final ValueChanged<MenuItem> onPicked;

  @override
  State<MenuItemSearchField> createState() => _MenuItemSearchFieldState();
}

class _MenuItemSearchFieldState extends State<MenuItemSearchField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  StreamSubscription<List<MenuItem>>? _sub;
  List<MenuItem> _items = const [];

  /// Bumped on every pick to remount the autocomplete. RawAutocomplete keeps
  /// the last selected option and ignores selecting it again, which would
  /// block adding the same item twice in a row.
  int _pickCount = 0;

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<IMenuRepository>()) {
      _sub = sl<IMenuRepository>().watchAll().listen((items) {
        if (!mounted) return;
        setState(() {
          _items = items.where((m) => m.isAvailable).toList()
            ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        });
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<MenuItem>(
        key: ValueKey(_pickCount),
        textEditingController: _controller,
        focusNode: _focus,
        displayStringForOption: (m) => m.title,
        optionsBuilder: (value) {
          final q = value.text.trim().toLowerCase();
          return q.isEmpty ? _items : _items.where((m) => m.title.toLowerCase().contains(q));
        },
        onSelected: (item) {
          widget.onPicked(item);
          // Ready for the next search; closing the list keeps the order visible.
          _controller.clear();
          _focus.unfocus();
          setState(() => _pickCount++);
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.orderSearchItems,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => onSubmitted(),
        ),
        optionsViewBuilder: (context, onSelected, options) {
          final list = options.toList();
          final highlighted = AutocompleteHighlightedOption.of(context);
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 320, maxWidth: constraints.maxWidth),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final m = list[i];
                    return ListTile(
                      dense: true,
                      tileColor: i == highlighted ? cs.secondaryContainer : null,
                      title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Text('₹${formatNumber(m.price)}/${normalizedUnit(m.unit)}'),
                      onTap: () => onSelected(m),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
