import 'dart:async';
import 'package:flutter/material.dart';

/// Keeps typing responsive and sends only the latest query after a short pause.
class AppSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final Duration debounce;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 350),
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  Timer? _timer;

  void _submit(String value) {
    _timer?.cancel();
    widget.onChanged(value.trim());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller,
        builder:
            (context, value, _) => TextField(
              controller: widget.controller,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                _timer?.cancel();
                if (value.isEmpty || widget.debounce == Duration.zero) {
                  _submit(value);
                } else {
                  _timer = Timer(widget.debounce, () => _submit(value));
                }
              },
              onSubmitted: (value) {
                _submit(value);
                FocusScope.of(context).unfocus();
              },
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon:
                    value.text.isEmpty
                        ? null
                        : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            widget.controller.clear();
                            _submit('');
                          },
                        ),
              ),
            ),
      );
}
