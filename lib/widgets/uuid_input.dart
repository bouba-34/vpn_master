import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class UuidInput extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;
  final bool enabled;

  const UuidInput({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.enabled = true
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
  void didUpdateWidget(UuidInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si l'état d'activation change et que le champ est désactivé, libérer le focus
    if (oldWidget.enabled != widget.enabled && !widget.enabled) {
      _focusNode.unfocus();
    }
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
              enabled: widget.enabled,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Entrez votre UUID',
                suffixIcon: !widget.enabled
                    ? const Icon(Icons.lock, size: 16, color: Colors.grey)
                    : null,
              ),
              onChanged: widget.onChanged,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          // Grisé quand désactivé
          color: widget.enabled
              ? Theme.of(context).textTheme.bodyLarge?.color
              : Theme.of(context).disabledColor,),
            ),
          ),
        ],
      ),
    );
  }
}