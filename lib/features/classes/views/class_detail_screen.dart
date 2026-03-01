import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../students/providers/student_provider.dart';
import '../../students/views/student_profile_screen.dart';

class ClassDetailScreen extends ConsumerStatefulWidget {
  final int classId;
  final String className;

  const ClassDetailScreen({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch students for this class when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentNotifierProvider.notifier).loadStudentsForClass(widget.classId);
    });
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Student', style: TextStyle(fontSize: 24)),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Student Full Name',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 18),
            autofocus: true,
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 18)),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                
                if (name.isNotEmpty) {
                  ref.read(studentNotifierProvider.notifier).addStudent(widget.classId, name);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid name', style: TextStyle(fontSize: 16)),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student', style: TextStyle(fontSize: 18)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} Roster'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity, // Full width button for large touch target
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showAddStudentDialog(context),
                icon: const Icon(Icons.add, size: 28),
                label: const Text(
                  'Add New Student',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Expanded(
            child: studentsState.when(
              data: (students) {
                if (students.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'This class roster is empty.\nTap "Add New Student" above to begin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey, height: 1.5),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (student.id != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentProfileScreen(
                                  studentId: student.id!,
                                  studentName: student.name,
                                ),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                student.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            title: Text(
                              student.name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 32),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error', style: const TextStyle(fontSize: 18, color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
