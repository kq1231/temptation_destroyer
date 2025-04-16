import 'package:flutter/material.dart';

/// A specialized input field for duas with formatting options
/// and suggested duas from Islamic sources.
class DuaInput extends StatefulWidget {
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final String? initialValue;
  final bool readOnly;
  final Function(bool)? onFocusChange;

  const DuaInput({
    super.key,
    required this.controller,
    this.validator,
    this.initialValue,
    this.readOnly = false,
    this.onFocusChange,
  });

  @override
  State<DuaInput> createState() => _DuaInputState();
}

class _DuaInputState extends State<DuaInput> {
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  bool _isFormatted = false;

  // Example list of common duas
  final List<String> _suggestionList = [
    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
    'رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ',
    'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
    'رَبِّ زِدْنِي عِلْمًا',
  ];

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (widget.onFocusChange != null) {
        widget.onFocusChange!(_focusNode.hasFocus);
      }

      setState(() {
        _showSuggestions = _focusNode.hasFocus;
      });
    });

    // Initialize with the initial value if provided
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Input field for dua
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Dua or Aspiration',
            hintText: 'Enter your dua or aspiration',
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Format toggle button
                IconButton(
                  icon: Icon(
                    _isFormatted ? Icons.text_fields : Icons.text_format,
                    color: _isFormatted
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  onPressed: _toggleFormatting,
                  tooltip:
                      _isFormatted ? 'Remove formatting' : 'Add formatting',
                ),

                // Show/hide suggestions button
                IconButton(
                  icon: Icon(
                    _showSuggestions
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: _showSuggestions
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSuggestions = !_showSuggestions;
                    });
                  },
                  tooltip: _showSuggestions
                      ? 'Hide suggestions'
                      : 'Show suggestions',
                ),
              ],
            ),
          ),
          validator: widget.validator,
          maxLines: 3,
          readOnly: widget.readOnly,
          textDirection: _containsArabic(widget.controller.text)
              ? TextDirection.rtl
              : TextDirection.ltr,
          style: _isFormatted
              ? const TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  letterSpacing: 0.5,
                )
              : null,
        ),

        // Dua suggestions
        if (_showSuggestions)
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(top: 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestionList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _suggestionList[index],
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  onTap: () {
                    widget.controller.text = _suggestionList[index];
                    setState(() {
                      _showSuggestions = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  /// Toggle formatting of the text
  void _toggleFormatting() {
    setState(() {
      _isFormatted = !_isFormatted;
    });
  }

  /// Check if text contains Arabic characters
  bool _containsArabic(String text) {
    // Unicode range for Arabic characters
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }
}
