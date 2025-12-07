import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker_plus/flutter_native_contact_picker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavouriteContactsScreen extends StatefulWidget {
  const FavouriteContactsScreen({super.key});

  @override
  State<FavouriteContactsScreen> createState() =>
      _FavouriteContactsScreenState();
}

class _FavouriteContactsScreenState extends State<FavouriteContactsScreen> {
  final FlutterContactPickerPlus _picker = FlutterContactPickerPlus();

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
      final phone = (contact.phoneNumbers?.isNotEmpty ?? false)
          ? contact.phoneNumbers!.first
          : "";

      if (name.isEmpty || phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contact must have name & phone")),
        );
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
        title: const Text("Favourite Contacts"),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () async {
              await saveContacts();
              Navigator.pop(context);
            },
            child: const Text("Done", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: pickContact,
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: names.isEmpty
          ? const Center(
              child: Text(
                "No favourite contacts yet.\nTap + to add.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: names.length,
              onReorder: reorderList,
              itemBuilder: (context, index) {
                return Card(
                  key: ValueKey(index),
                  color: Colors.grey[900],
                  child: ListTile(
                    title: Text(
                      names[index],
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    subtitle: Text(
                      numbers[index],
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => deleteContact(index),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
