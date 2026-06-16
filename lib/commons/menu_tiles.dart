// Author: Ujwal N K
// Created On: 2026.06.12
// Custom auto-saving SharedPreferences UI components

import 'package:flutter/material.dart';
import 'package:moto_dash/service/rgb_color_picker.dart'; // Keep your custom color picker dialog
import 'package:shared_preferences/shared_preferences.dart';

const Color _textColor = Colors.white;

// ============================================================================
// 1. CHECKBOX TILE
// ============================================================================
class PrefCheckboxTile extends StatefulWidget {
  final String title;
  final String prefKey;
  final bool defaultValue;
  final ValueChanged<bool>? onChanged;

  const PrefCheckboxTile({
    super.key,
    required this.title,
    required this.prefKey,
    required this.defaultValue,
    this.onChanged,
  });

  @override
  State<PrefCheckboxTile> createState() => _PrefCheckboxTileState();
}

class _PrefCheckboxTileState extends State<PrefCheckboxTile> {
  bool? _currentValue;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentValue = prefs.getBool(widget.prefKey) ?? widget.defaultValue;
    });
  }

  Future<void> _updateValue(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefKey, newValue);
    setState(() => _currentValue = newValue);
    if (widget.onChanged != null) widget.onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentValue == null) return const SizedBox.shrink();

    return CheckboxListTile(
      title: Text(widget.title, style: const TextStyle(color: _textColor)),
      value: _currentValue,
      onChanged: (v) => _updateValue(v!),
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.blueGrey,
      checkColor: Colors.black,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}

// ============================================================================
// 2. TEXT FIELD TILE
// ============================================================================
class PrefTextFieldTile extends StatefulWidget {
  final String label;
  final String prefKey;
  final String defaultValue;
  final TextInputType inputType;

  const PrefTextFieldTile({
    super.key,
    required this.label,
    required this.prefKey,
    required this.defaultValue,
    this.inputType = TextInputType.text,
  });

  @override
  State<PrefTextFieldTile> createState() => _PrefTextFieldTileState();
}

class _PrefTextFieldTileState extends State<PrefTextFieldTile> {
  final _controller = TextEditingController();
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    final prefs = await SharedPreferences.getInstance();
    // Handles reading strings directly or casting doubles safely to matching text representation
    final val = prefs.get(widget.prefKey)?.toString() ?? widget.defaultValue;
    _controller.text = val;
    setState(() => _isLoaded = true);
  }

  Future<void> _saveValue(String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.inputType == TextInputType.number) {
      final parsedNum = double.tryParse(text) ?? double.tryParse(widget.defaultValue) ?? 0.0;
      await prefs.setDouble(widget.prefKey, parsedNum);
    } else {
      await prefs.setString(widget.prefKey, text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: _controller,
        keyboardType: widget.inputType,
        style: const TextStyle(color: _textColor),
        onChanged: _saveValue,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(color: _textColor),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey)),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. SLIDER TILE (With live numeric percentage tracker)
// ============================================================================
class PrefSliderTile extends StatefulWidget {
  final String title;
  final String prefKey;
  final double defaultValue;
  final double min;
  final double max;

  const PrefSliderTile({
    super.key,
    required this.title,
    required this.prefKey,
    required this.defaultValue,
    this.min = 0,
    this.max = 100,
  });

  @override
  State<PrefSliderTile> createState() => _PrefSliderTileState();
}

class _PrefSliderTileState extends State<PrefSliderTile> {
  double? _currentValue;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentValue = prefs.getDouble(widget.prefKey) ?? widget.defaultValue;
    });
  }

  Future<void> _updateValue(double newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(widget.prefKey, newValue);
    setState(() => _currentValue = newValue);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentValue == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            // The filled part of the slider bar
            activeTrackColor: Colors.red,
            // The handle/knob
            thumbColor: Colors.redAccent,
            // The halo/glow that appears when you tap the thumb
            overlayColor: Colors.red.withAlpha(32),
            // The unfilled part of the slider bar
            inactiveTrackColor: Colors.white24,
            // The little tick marks if you use divisions
            activeTickMarkColor: Colors.black26,
            inactiveTickMarkColor: Colors.white24,
          ),
          child: Slider(
            value: _currentValue!,
            min: widget.min,
            max: widget.max,
            divisions: (widget.max - widget.min).toInt(),
            onChanged: _updateValue,
          ),
        ),
        Text("${_currentValue!.toInt()}%", style: const TextStyle(color: _textColor)),
      ],
    );
  }
}

// ============================================================================
// 4. COLOR TILE
// ============================================================================
class PrefColorTile extends StatefulWidget {
  final String label;
  final String prefKey;
  final Color defaultValue;

  const PrefColorTile({super.key, required this.label, required this.prefKey, required this.defaultValue});

  @override
  State<PrefColorTile> createState() => _PrefColorTileState();
}

class _PrefColorTileState extends State<PrefColorTile> {
  Color? _currentColor;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    final prefs = await SharedPreferences.getInstance();
    final colorInt = prefs.getInt(widget.prefKey);
    setState(() {
      _currentColor = colorInt != null ? Color(colorInt) : widget.defaultValue;
    });
  }

  Future<void> _updateColor(Color targetColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(widget.prefKey, targetColor.toARGB32());
    setState(() => _currentColor = targetColor);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentColor == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (_) => HexWheelColorPickerDialog(color: _currentColor!, onChanged: _updateColor),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: const TextStyle(color: _textColor)),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrefSwitchTile extends StatefulWidget {
  final String title;
  final String prefKey;
  final bool defaultValue;
  final ValueChanged<bool>? onChanged;

  const PrefSwitchTile({
    super.key,
    required this.title,
    required this.prefKey,
    required this.defaultValue,
    this.onChanged,
  });

  @override
  State<PrefSwitchTile> createState() => _PrefSwitchTileState();
}

// ============================================================================
// 5. Toggle Switch
// ============================================================================
class _PrefSwitchTileState extends State<PrefSwitchTile> {
  bool? _currentValue;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentValue = prefs.getBool(widget.prefKey) ?? widget.defaultValue;
    });
  }

  Future<void> _updateValue(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefKey, newValue);
    setState(() => _currentValue = newValue);
    if (widget.onChanged != null) widget.onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentValue == null) return const SizedBox.shrink();

    return SwitchListTile(
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      value: _currentValue!,
      onChanged: _updateValue,
      contentPadding: EdgeInsets.zero,
      // activeColor: Colors.blueGrey,
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.red; // Color when ON
        }
        return null; // Uses default fallback when OFF
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.red.withAlpha(100); // Track tint when ON
        }
        return null;
      }),
    );
  }
}
