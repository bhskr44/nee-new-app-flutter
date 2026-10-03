import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A -/+ stepper with a directly-editable number field in the middle —
/// typing a large quantity (e.g. 1000 bags of cement) beats tapping "+"
/// hundreds of times, while the buttons still handle small adjustments.
class QuantityStepper extends StatefulWidget {
  final int quantity;
  final int min;
  final int? max;
  final ValueChanged<int> onChanged;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.min = 1,
    this.max,
  });

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late final TextEditingController _ctrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.quantity}');
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _commit(_ctrl.text);
    });
  }

  @override
  void didUpdateWidget(covariant QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't clobber what the user is actively typing.
    if (!_focusNode.hasFocus && widget.quantity != oldWidget.quantity) {
      _ctrl.text = '${widget.quantity}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int _clamp(int value) {
    var v = value < widget.min ? widget.min : value;
    if (widget.max != null && v > widget.max!) v = widget.max!;
    return v;
  }

  void _commit(String text) {
    final parsed = int.tryParse(text.trim());
    final value = _clamp(parsed ?? widget.quantity);
    _ctrl.text = '$value';
    if (value != widget.quantity) widget.onChanged(value);
  }

  void _step(int delta) {
    final next = _clamp(widget.quantity + delta);
    _ctrl.text = '$next';
    if (next != widget.quantity) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF667085)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: widget.quantity > widget.min ? () => _step(-1) : null,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(8),
          ),
          SizedBox(
            width: 56,
            child: TextField(
              controller: _ctrl,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
              ),
              onSubmitted: _commit,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: (widget.max == null || widget.quantity < widget.max!) ? () => _step(1) : null,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}
