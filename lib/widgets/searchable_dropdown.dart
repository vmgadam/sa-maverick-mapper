import 'package:flutter/material.dart';

class SearchableDropdownItem {
  final String value;
  final String label;
  final String subtitle;

  SearchableDropdownItem({
    required this.value,
    required this.label,
    required this.subtitle,
  });
}

class SearchableDropdown extends StatefulWidget {
  final List<SearchableDropdownItem> items;
  final Widget hint;
  final Function(String?) onChanged;

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final TextEditingController _searchController = TextEditingController();
  bool _isOpen = false;
  String _searchQuery = '';
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _searchController.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    if (!_disposed) {
      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isOpen = true);
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!_disposed) {
      setState(() => _isOpen = false);
    }
  }

  List<SearchableDropdownItem> get filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items.where((item) {
      return item.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width + 50, // Add some extra width for the scrollbar
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 300,
                minWidth: size.width,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        hintText: 'Search fields or values...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search, size: 20),
                      ),
                      onChanged: (value) {
                        if (!_disposed) {
                          setState(() => _searchQuery = value);
                          _overlayEntry?.markNeedsBuild();
                        }
                      },
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return ListTile(
                          dense: true,
                          title: Text(item.label,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onTap: () {
                            if (!_disposed) {
                              widget.onChanged(item.value);
                              _hideOverlay();
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: () {
          if (_isOpen) {
            _hideOverlay();
          } else {
            _showOverlay();
          }
        },
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(child: widget.hint),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 20,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
