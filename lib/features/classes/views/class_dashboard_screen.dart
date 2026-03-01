import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../../assignments/views/class_assignments_screen.dart';

class ClassDashboardScreen extends ConsumerStatefulWidget {
  final int schoolId;
  final String schoolName;

  const ClassDashboardScreen({
    Key? key,
    required this.schoolId,
    required this.schoolName,
  }) : super(key: key);

  @override
  ConsumerState<ClassDashboardScreen> createState() => _ClassDashboardScreenState();
}

class _ClassDashboardScreenState extends ConsumerState<ClassDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classNotifierProvider.notifier).loadClassesForSchool(widget.schoolId);
    });
  }

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final yearController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Class Name (e.g., Math 101)'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Academic Year (e.g., 2023-2024)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final year = yearController.text.trim();
                
                if (name.isNotEmpty && year.isNotEmpty) {
                  ref.read(classNotifierProvider.notifier).addClass(widget.schoolId, name, year);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out all fields')),
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
  Widget build(BuildContext context) {
    final classesState = ref.watch(classNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.schoolName} Classes'),
      ),
      body: classesState.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(
              child: Text(
                'No classes added to this school yet.\nTap + to create one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final model = classes[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    child: Icon(Icons.class_),
                  ),
                  title: Text(
                    model.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Academic Year: ${model.academicYear}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      if (model.id != null) {
                        ref.read(classNotifierProvider.notifier).deleteClass(model.id!);
                      }
                    },
                  ),
                  onTap: () {
                    if (model.id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassAssignmentsScreen(
                            classId: model.id!,
                            className: model.name,
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
          child: Text('Error loading classes: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClassDialog(context, ref),
        child: const Icon(Icons.add),
        tooltip: 'Add Class',
      ),
    );
  }
}
