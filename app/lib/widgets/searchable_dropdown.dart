import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final String labelText;
  final IconData prefixIcon;
  final String? Function(T?)? validator;
  final bool enabled;

  const SearchableDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.labelText,
    this.prefixIcon = Icons.search,
    this.validator,
    this.enabled = true,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void didUpdateWidget(SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItems = widget.items;
      _searchController.clear();
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          return widget.itemLabel(item).toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _showSearchDialog() async {
    _searchController.clear();
    _filteredItems = widget.items;

    final selected = await showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Buscar ${widget.labelText}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Buscar...',
                        prefixIcon: Icon(widget.prefixIcon),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          _filterItems(value);
                        });
                      },
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: _filteredItems.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No se encontraron resultados'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                final isSelected = item == widget.value;
                                return ListTile(
                                  title: Text(widget.itemLabel(item)),
                                  selected: isSelected,
                                  selectedTileColor: Colors.teal.withOpacity(0.1),
                                  leading: isSelected
                                      ? const Icon(Icons.check_circle, color: Colors.teal)
                                      : null,
                                  onTap: () {
                                    Navigator.pop(context, item);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (FormFieldState<T> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.enabled ? _showSearchDialog : null,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  prefixIcon: Icon(widget.prefixIcon),
                  suffixIcon: widget.value != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: widget.enabled
                              ? () => widget.onChanged(null)
                              : null,
                        )
                      : const Icon(Icons.arrow_drop_down),
                  border: const OutlineInputBorder(),
                  enabled: widget.enabled,
                  errorText: field.errorText,
                ),
                child: widget.value != null
                    ? Text(widget.itemLabel(widget.value as T))
                    : Text(
                        'Seleccionar...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

