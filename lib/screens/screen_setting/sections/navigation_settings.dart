// Author: Ujwal N K /w Claude
// Created: 2026.08.02
// "Navigation Favourites" settings section: manage saved destinations for quick navigation.

import 'package:flutter/material.dart';
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/google_maps_url_parser.dart';
import 'package:moto_dash/commons/navigation_destination_model.dart';
import 'package:moto_dash/screens/screen_setting/setting_card.dart';

class NavigationSettings extends StatefulWidget {
  const NavigationSettings({super.key});

  @override
  State<NavigationSettings> createState() => _NavigationSettingsState();
}

class _NavigationSettingsState extends State<NavigationSettings> {
  static const Color textColor = Colors.white;

  late List<NavigationDestinationModel> _favourites;

  @override
  void initState() {
    super.initState();
    _favourites = ConfigProvider.navigationFavourites;
  }

  Future<void> _persist() => ConfigProvider.setNavigationFavourites(_favourites);

  Future<void> _addFavourite() async {
    final result = await _showEditDialog();
    if (result == null) return;
    setState(() => _favourites.add(result));
    await _persist();
  }

  Future<void> _renameFavourite(int index) async {
    final result = await _showEditDialog(existing: _favourites[index]);
    if (result == null) return;
    setState(() => _favourites[index] = result);
    await _persist();
  }

  Future<void> _deleteFavourite(int index) async {
    setState(() => _favourites.removeAt(index));
    await _persist();
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _favourites.removeAt(oldIndex);
      _favourites.insert(newIndex, item);
    });
    await _persist();
  }

  /// Shows a dialog to create a new favourite (name + coordinates), or rename an existing one (name only —
  /// coordinates are locked once a destination is saved, since renaming shouldn't silently move the pin).
  Future<NavigationDestinationModel?> _showEditDialog({NavigationDestinationModel? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? "");
    final latController = TextEditingController(text: existing?.latitude.toString() ?? "");
    final lngController = TextEditingController(text: existing?.longitude.toString() ?? "");
    final urlController = TextEditingController();

    return showDialog<NavigationDestinationModel>(
      context: context,
      builder: (dialogContext) {
        bool isResolving = false;
        String? urlError;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> extractFromUrl() async {
              final url = urlController.text.trim();
              if (url.isEmpty) return;

              setDialogState(() {
                isResolving = true;
                urlError = null;
              });

              final result = await GoogleMapsUrlParser.extractLatLng(url);

              setDialogState(() {
                isResolving = false;
                if (result == null) {
                  urlError = "Couldn't find coordinates in that link.";
                } else {
                  latController.text = result.$1.toString();
                  lngController.text = result.$2.toString();
                }
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(
                existing == null ? "Add Destination" : "Rename Destination",
                style: const TextStyle(color: textColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: "Name",
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  if (existing == null) ...[
                    TextField(
                      controller: urlController,
                      style: const TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: "Paste Google Maps link",
                        labelStyle: const TextStyle(color: Colors.white54),
                        errorText: urlError,
                        errorMaxLines: 2,
                        suffixIcon: isResolving
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.pin_drop_outlined, color: Colors.white54),
                                onPressed: extractFromUrl,
                              ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Or enter coordinates manually below",
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                  TextField(
                    controller: latController,
                    enabled: existing == null,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    style: const TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: "Latitude",
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  TextField(
                    controller: lngController,
                    enabled: existing == null,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    style: const TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: "Longitude",
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final lat = double.tryParse(latController.text.trim());
                    final lng = double.tryParse(lngController.text.trim());
                    if (name.isEmpty || lat == null || lng == null) return;

                    Navigator.pop(
                      dialogContext,
                      existing?.copyWith(name: name) ??
                          NavigationDestinationModel(
                            id: DateTime.now().microsecondsSinceEpoch.toString(),
                            name: name,
                            latitude: lat,
                            longitude: lng,
                          ),
                    );
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: "Saved destination",
      children: [
        if (_favourites.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 12),
            child: Text("No saved destinations yet.", style: TextStyle(color: Colors.white54)),
          ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: _reorder,
          itemCount: _favourites.length,
          itemBuilder: (context, index) {
            final favourite = _favourites[index];
            return Container(
              key: ValueKey(favourite.id),
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.drag_handle, color: Colors.white54),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(favourite.name, style: const TextStyle(color: textColor)),
                        Text(
                          "${favourite.latitude.toStringAsFixed(5)}, ${favourite.longitude.toStringAsFixed(5)}",
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white54),
                    onPressed: () => _renameFavourite(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white54),
                    onPressed: () => _deleteFavourite(index),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: TextButton.icon(
            onPressed: _addFavourite,
            icon: const Icon(Icons.add, color: textColor),
            label: const Text("Add Destination", style: TextStyle(color: textColor)),
          ),
        ),
      ],
    );
  }
}
