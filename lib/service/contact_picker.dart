import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactPickerScreen extends StatefulWidget {
  final List<String> preSelected; // already chosen contacts (phone numbers)

  const ContactPickerScreen({super.key, required this.preSelected});

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  List<Contact> contacts = [];
  List<String> selectedContacts = [];

  @override
  void initState() {
    super.initState();
    selectedContacts = List.from(widget.preSelected);
    loadContacts();
  }

  Future<void> loadContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final list = await FlutterContacts.getContacts(withProperties: true);
      setState(() => contacts = list);
    }
  }

  void toggleSelection(String phone) {
    setState(() {
      if (selectedContacts.contains(phone)) {
        selectedContacts.remove(phone);
      } else {
        if (selectedContacts.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You can pick maximum 5 contacts")),
          );
          return;
        }
        selectedContacts.add(phone);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Favourite Contacts"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, selectedContacts);
            },
            child: const Text(
              "Done",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: contacts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final c = contacts[index];

                // skip contacts with no numbers
                if (c.phones.isEmpty) return const SizedBox();

                final phone = c.phones.first.number;
                final selected = selectedContacts.contains(phone);

                return ListTile(
                  title: Text(c.displayName),
                  subtitle: Text(phone),
                  trailing: Checkbox(
                    value: selected,
                    onChanged: (_) => toggleSelection(phone),
                  ),
                  onTap: () => toggleSelection(phone),
                );
              },
            ),
    );
  }
}
