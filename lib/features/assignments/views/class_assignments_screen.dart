import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/assignment_provider.dart';
import '../../gradebook/views/gradebook_grid_screen.dart';

const List<String> kMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class ClassAssignmentsScreen extends ConsumerStatefulWidget {
  final int classId;
  final String className;

  const ClassAssignmentsScreen({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  ConsumerState<ClassAssignmentsScreen> createState() => _ClassAssignmentsScreenState();
}

class _ClassAssignmentsScreenState extends ConsumerState<ClassAssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentNotifierProvider.notifier).loadAssignmentsForClass(widget.classId);
    });
  }

  void _showAddAssignmentDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final maxPointsController = TextEditingController(text: '100');
    String selectedMonth = kMonths[DateTime.now().month - 1];
    String selectedYear = DateTime.now().year.toString();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add New Assignment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Assignment Name (e.g., Midterm)'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: maxPointsController,
                      decoration: const InputDecoration(labelText: 'Max Points'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedMonth,
                            decoration: const InputDecoration(labelText: 'Month'),
                            items: kMonths.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (val) => setStateDialog(() => selectedMonth = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedYear,
                            decoration: const InputDecoration(labelText: 'Year'),
                            items: ['2023', '2024', '2025', '2026'].map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: (val) => setStateDialog(() => selectedYear = val!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final maxPts = double.tryParse(maxPointsController.text.trim());
                    
                    if (name.isNotEmpty && maxPts != null && maxPts > 0) {
                      ref.read(assignmentNotifierProvider.notifier).addAssignment(
                        widget.classId, name, selectedMonth, selectedYear, maxPts
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid name and max points')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsState = ref.watch(assignmentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} Assignments'),
      ),
      body: assignmentsState.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return const Center(
              child: Text(
                'No assignments created yet.\nTap + to set one up.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.assignment),
                  ),
                  title: Text(
                    assignment.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text('${assignment.month} ${assignment.year} • Max: ${assignment.maxPoints} pts'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.assessment, color: Colors.blue),
                        tooltip: 'Batch Grade',
                        onPressed: () {
                          if (assignment.id != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GradebookGridScreen(
                                  assignment: assignment,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (assignment.id != null) {
                            ref.read(assignmentNotifierProvider.notifier).deleteAssignment(assignment.id!);
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    if (assignment.id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GradebookGridScreen(
                            assignment: assignment,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAssignmentDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Assignment'),
      ),
    );
  }
}
