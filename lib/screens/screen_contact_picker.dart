import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker_plus/flutter_native_contact_picker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavouriteContactsScreen extends StatefulWidget {
  const FavouriteContactsScreen({super.key});

  @override
  State<FavouriteContactsScreen> createState() => _FavouriteContactsScreenState();
}

class _FavouriteContactsScreenState extends State<FavouriteContactsScreen> {
  final FlutterContactPickerPlus _picker = FlutterContactPickerPlus();

  static const Color _kBackgroundColor = Color(0xFF121212);
  static const Color _kCardColor = Color(0xFF1E1E1E);
  static const Color _kTextColor = Color(0xFFFFFFFF);

  List<String> names = [];
  List<String> numbers = [];

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  // ------------------------------------------------------------
  // Load from shared preferences
  // ------------------------------------------------------------
  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();

    // TODO: Use ConfigProvider here.
    setState(() {
      names = prefs.getStringList("fav_contact_names") ?? [];
      numbers = prefs.getStringList("fav_contact_numbers") ?? [];
    });
  }

  // ------------------------------------------------------------
  // Save to shared preferences
  // ------------------------------------------------------------
  Future<void> saveContacts() async {
    final prefs = await SharedPreferences.getInstance();

    // TODO: Use ConfigProvider here.
    await prefs.setStringList("fav_contact_names", names);
    await prefs.setStringList("fav_contact_numbers", numbers);
  }

  // ------------------------------------------------------------
  // Pick a new contact
  // ------------------------------------------------------------
  Future<void> pickContact() async {
    try {
      final contact = await _picker.selectContact();
      if (contact == null) return;

      final name = contact.fullName ?? "";
      final phone = (contact.phoneNumbers?.isNotEmpty ?? false) ? contact.phoneNumbers!.first : "";

      if (name.isEmpty || phone.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contact must have name & phone")));
        return;
      }

      setState(() {
        names.add(name);
        numbers.add(phone);
      });
    } catch (e) {
      debugPrint("Error picking contact: $e");
    }
  }

  // ------------------------------------------------------------
  // Delete a contact
  // ------------------------------------------------------------
  void deleteContact(int index) {
    setState(() {
      names.removeAt(index);
      numbers.removeAt(index);
    });
  }

  // ------------------------------------------------------------
  // Reorder contacts (drag & drop)
  // ------------------------------------------------------------
  void reorderList(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;

      final nameItem = names.removeAt(oldIndex);
      final numberItem = numbers.removeAt(oldIndex);

      names.insert(newIndex, nameItem);
      numbers.insert(newIndex, numberItem);
    });
  }

  // ------------------------------------------------------------
  // BUILD UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: _kTextColor,
        title: const Text("Favourite Contacts"),
        backgroundColor: _kBackgroundColor,
        actions: [
          TextButton(
            onPressed: () async {
              await saveContacts();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Done", style: TextStyle(color: _kTextColor)),
          ),
        ],
      ),
      backgroundColor: _kBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: pickContact,
        backgroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
      body: names.isEmpty
          ? const Center(
              child: Text(
                "Tap + to add",
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTextColor, fontSize: 16),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: names.length,
              onReorder: reorderList,
              itemBuilder: (context, index) {
                return Card(
                  key: ValueKey(index),
                  color: _kCardColor,
                  child: ListTile(
                    title: Text(names[index], style: const TextStyle(color: _kTextColor, fontSize: 18)),
                    subtitle: Text(numbers[index], style: const TextStyle(color: Colors.white70)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                      onPressed: () => deleteContact(index),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
