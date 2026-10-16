import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';

typedef ItemBuilder<T> = String Function(T item);
typedef ItemComparator<T> = int Function(T a, T b);

/// A searchable dropdown widget that opens a bottom sheet with a filtered list.
class AppSearchableDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ItemBuilder<T> itemBuilder;
  final ValueChanged<T?> onChanged;
  final ItemComparator<T>? itemComparator;
  final IconData? icon;
  final String? Function(T?)? validator;
  final bool readOnly;

  const AppSearchableDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
    this.value,
    this.itemComparator,
    this.icon,
    this.validator,
    this.readOnly = false,
  });

  @override
  State<AppSearchableDropdown<T>> createState() =>
      _AppSearchableDropdownState<T>();
}

class _AppSearchableDropdownState<T> extends State<AppSearchableDropdown<T>> {
  late TextEditingController _searchController;
  late List<T> _filteredItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initializeItems();
  }

  @override
  void didUpdateWidget(covariant AppSearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _initializeItems();
    }
  }

  void _initializeItems() {
    _filteredItems = List.from(widget.items);
    if (widget.itemComparator != null) {
      _filteredItems.sort(widget.itemComparator!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredItems = widget.items
            .where(
              (item) =>
                  widget.itemBuilder(item).toLowerCase().contains(lowerQuery),
            )
            .toList();
      }
      if (widget.itemComparator != null) {
        _filteredItems.sort(widget.itemComparator!);
      }
    });
  }

  void _openDialog() {
    showDialog<T>(
      context: context,
      useRootNavigator: false,
      builder: (context) => _SearchDialog<T>(
        title: widget.label,
        items: _filteredItems,
        itemBuilder: widget.itemBuilder,
        onSearch: _filterItems,
        onSelected: (selectedItem) {
          Navigator.pop(context, selectedItem);
        },
        searchController: _searchController,
      ),
    ).then((selectedItem) {
      if (selectedItem != null) {
        widget.onChanged(selectedItem);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.value != null
        ? widget.itemBuilder(widget.value as T)
        : 'Selecione';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.readOnly ? null : _openDialog,
      child: InputDecorator(
        decoration: InputDecoration(
          label: Text(widget.label),
          prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        child: Text(
          displayText,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: widget.value != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SearchDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final ItemBuilder<T> itemBuilder;
  final ValueChanged<String> onSearch;
  final ValueChanged<T> onSelected;
  final TextEditingController searchController;

  const _SearchDialog({
    required this.title,
    required this.items,
    required this.itemBuilder,
    required this.onSearch,
    required this.onSelected,
    required this.searchController,
  });

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  late List<T> _currentItems;

  @override
  void initState() {
    super.initState();
    _currentItems = widget.items;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Selecionar ${widget.title.toLowerCase()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: widget.searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: widget.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          widget.searchController.clear();
                          widget.onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppSpacing.borderRadiusMd,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _currentItems = widget.items
                      .where(
                        (item) => widget
                            .itemBuilder(item)
                            .toLowerCase()
                            .contains(value.toLowerCase()),
                      )
                      .toList();
                });
                widget.onSearch(value);
              },
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Expanded(
            child: _currentItems.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Nenhum item encontrado'),
                  )
                : ListView.builder(
                    itemCount: _currentItems.length,
                    itemBuilder: (context, index) {
                      final item = _currentItems[index];
                      return ListTile(
                        title: Text(widget.itemBuilder(item)),
                        onTap: () => widget.onSelected(item),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }
}
