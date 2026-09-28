import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';

typedef GroupedItemBuilder<T> = String Function(T item);

class AppDropdownGroup<T> {
  final String name;
  final List<T> items;

  const AppDropdownGroup({required this.name, required this.items});
}

typedef GroupedItemComparator<T> = int Function(T a, T b);

/// A grouped dropdown widget with search capability.
class AppGroupedDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<AppDropdownGroup<T>> groups;
  final GroupedItemBuilder<T> itemBuilder;
  final ValueChanged<T?> onChanged;
  final GroupedItemComparator<T>? itemComparator;
  final IconData? icon;
  final String? Function(T?)? validator;

  const AppGroupedDropdown({
    super.key,
    required this.label,
    required this.groups,
    required this.itemBuilder,
    required this.onChanged,
    this.value,
    this.itemComparator,
    this.icon,
    this.validator,
  });

  @override
  State<AppGroupedDropdown<T>> createState() => _AppGroupedDropdownState<T>();
}

class _AppGroupedDropdownState<T> extends State<AppGroupedDropdown<T>> {
  late TextEditingController _searchController;
  late List<AppDropdownGroup<T>> _filteredGroups;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initializeGroups();
  }

  @override
  void didUpdateWidget(covariant AppGroupedDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groups != widget.groups) {
      _initializeGroups();
    }
  }

  void _initializeGroups() {
    _filteredGroups = widget.groups.map((group) {
      final sortedItems = List<T>.from(group.items);
      if (widget.itemComparator != null) {
        sortedItems.sort(widget.itemComparator!);
      }
      return AppDropdownGroup<T>(name: group.name, items: sortedItems);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterGroups(String query) {
    setState(() {
      if (query.isEmpty) {
        _initializeGroups();
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredGroups = widget.groups.map((group) {
          final filteredItems = group.items
              .where(
                (item) =>
                    widget.itemBuilder(item).toLowerCase().contains(lowerQuery),
              )
              .toList();
          if (widget.itemComparator != null) {
            filteredItems.sort(widget.itemComparator!);
          }
          return AppDropdownGroup(name: group.name, items: filteredItems);
        }).toList();
        _filteredGroups.removeWhere((group) => group.items.isEmpty);
      }
    });
  }

  void _openDialog() {
    showDialog<T>(
      context: context,
      useRootNavigator: false,
      builder: (context) => _GroupedSearchDialog<T>(
        title: widget.label,
        groups: _filteredGroups,
        itemBuilder: widget.itemBuilder,
        onSearch: _filterGroups,
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
      onTap: _openDialog,
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

class _GroupedSearchDialog<T> extends StatefulWidget {
  final String title;
  final List<AppDropdownGroup<T>> groups;
  final GroupedItemBuilder<T> itemBuilder;
  final ValueChanged<String> onSearch;
  final ValueChanged<T> onSelected;
  final TextEditingController searchController;

  const _GroupedSearchDialog({
    required this.title,
    required this.groups,
    required this.itemBuilder,
    required this.onSearch,
    required this.onSelected,
    required this.searchController,
  });

  @override
  State<_GroupedSearchDialog<T>> createState() =>
      _GroupedSearchDialogState<T>();
}

class _GroupedSearchDialogState<T> extends State<_GroupedSearchDialog<T>> {
  late List<AppDropdownGroup<T>> _currentGroups;

  @override
  void initState() {
    super.initState();
    _currentGroups = widget.groups;
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
                  final lowerQuery = value.toLowerCase();
                  _currentGroups = widget.groups.map((group) {
                    final filteredItems = group.items
                        .where(
                          (item) => widget
                              .itemBuilder(item)
                              .toLowerCase()
                              .contains(lowerQuery),
                        )
                        .toList();
                    return AppDropdownGroup(
                      name: group.name,
                      items: filteredItems,
                    );
                  }).toList();
                  _currentGroups.removeWhere((group) => group.items.isEmpty);
                });
                widget.onSearch(value);
              },
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Expanded(
            child: _currentGroups.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Nenhum item encontrado'),
                  )
                : ListView.builder(
                    itemCount: _currentGroups.fold<int>(
                      0,
                      (sum, group) =>
                          sum +
                          group.items.length +
                          (group.items.isNotEmpty ? 1 : 0),
                    ),
                    itemBuilder: (context, index) {
                      var currentIndex = 0;
                      for (final group in _currentGroups) {
                        // Render group header
                        if (group.items.isNotEmpty) {
                          if (currentIndex == index) {
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.md,
                                0,
                                AppSpacing.sm,
                              ),
                              child: Text(
                                group.name,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                              ),
                            );
                          }
                          currentIndex++;

                          // Render items in group
                          for (final item in group.items) {
                            if (currentIndex == index) {
                              return ListTile(
                                title: Text(widget.itemBuilder(item)),
                                contentPadding: EdgeInsets.only(
                                  left: AppSpacing.xl * 1.5,
                                ),
                                onTap: () => widget.onSelected(item),
                              );
                            }
                            currentIndex++;
                          }
                        }
                      }
                      return const SizedBox.shrink();
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
