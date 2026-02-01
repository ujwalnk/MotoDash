import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

class HexWheelColorPickerDialog extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onChanged;

  const HexWheelColorPickerDialog({
    super.key,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      title: const Text('Select color', style: TextStyle(color: Colors.white)),

      content: SizedBox(
        width: 320,
        child: ColorPicker(
          color: color,
          onColorChanged: onChanged,
          mainAxisSize: MainAxisSize.min,

          // ✅ Enable wheel + custom picker
          pickersEnabled: {
            ColorPickerType.primary: false,
            ColorPickerType.accent: false,
            ColorPickerType.wheel: true,
            ColorPickerType.custom: true,
          },

          // ✅ Editable HEX input
          showColorCode: true,
          colorCodeReadOnly: false,
          enableShadesSelection: false,
          copyPasteBehavior: ColorPickerCopyPasteBehavior(
            // copyButton: false,
            // pasteButton: false,
            editFieldCopyButton: false,
          ),

          // ❌ Clean UI
          showColorName: false,
          showMaterialName: false,
          // showRecentColors: true,
          // opacitySubheading: "Opacity",

          // Optional
          enableOpacity: true, // set false if you don’t want alpha
          // showEditIconButton: true,
          colorCodeTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
