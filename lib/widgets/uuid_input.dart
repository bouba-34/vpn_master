import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class UuidInput extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;

  const UuidInput({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<UuidInput> createState() => _UuidInputState();
}

class _UuidInputState extends State<UuidInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Entrez votre UUID',
              ),
              onChanged: widget.onChanged,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}