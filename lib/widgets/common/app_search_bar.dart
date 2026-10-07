import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppSearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterPressed;
  final String hintText;

  const AppSearchBar({
    super.key,
    this.onChanged,
    this.onFilterPressed,
    this.hintText = 'Search items...',
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();

    widget.onChanged?.call('');

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          widget.onChanged?.call(value);
          setState(() {});
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: AppColors.secondaryText,
          ),

          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.secondaryText,
          ),

          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: _clearSearch,
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.secondaryText,
                  ),
                )
              : null,

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}