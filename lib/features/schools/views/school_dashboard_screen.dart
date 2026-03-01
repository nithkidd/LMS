import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/school_provider.dart';
import '../../classes/views/class_dashboard_screen.dart';

class SchoolDashboardScreen extends ConsumerWidget {
  const SchoolDashboardScreen({Key? key}) : super(key: key);

  void _showAddSchoolDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New School'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'School Name (e.g., Lincoln High)'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                
                if (name.isNotEmpty) {
                  ref.read(schoolNotifierProvider.notifier).addSchool(name);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a school name')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolsState = ref.watch(schoolNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schools'),
      ),
      body: schoolsState.when(
        data: (schools) {
          if (schools.isEmpty) {
            return const Center(
              child: Text(
                'No schools added yet. Tap + to begin.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: schools.length,
            itemBuilder: (context, index) {
              final school = schools[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    child: Icon(Icons.account_balance), // School icon
                  ),
                  title: Text(
                    school.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      if (school.id != null) {
                        ref.read(schoolNotifierProvider.notifier).deleteSchool(school.id!);
                      }
                    },
                  ),
                  onTap: () {
                    if (school.id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassDashboardScreen(
                            schoolId: school.id!,
                            schoolName: school.name,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSchoolDialog(context, ref),
        child: const Icon(Icons.add),
        tooltip: 'Add School',
      ),
    );
  }
}
