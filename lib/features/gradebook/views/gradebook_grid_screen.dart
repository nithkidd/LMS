import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../assignments/models/assignment_model.dart';
import '../../students/providers/student_provider.dart';
import '../providers/score_provider.dart';
import '../models/score_model.dart';

class GradebookGridScreen extends ConsumerStatefulWidget {
  final AssignmentModel assignment;

  const GradebookGridScreen({
    Key? key,
    required this.assignment,
  }) : super(key: key);

  @override
  ConsumerState<GradebookGridScreen> createState() => _GradebookGridScreenState();
}

class _GradebookGridScreenState extends ConsumerState<GradebookGridScreen> {
  // We use this map to store FocusNodes and Controllers for rapid data entry
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load all students and scores for this assignment
      ref.read(studentNotifierProvider.notifier).loadStudentsForClass(widget.assignment.classId);
      ref.read(scoreNotifierProvider.notifier).loadScoresForAssignment(widget.assignment.id!);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentNotifierProvider);
    final scoresState = ref.watch(scoreNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignment.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Max Points: ${widget.assignment.maxPoints} • ${widget.assignment.month} ${widget.assignment.year}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
      body: studentsState.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No students in this class.'));
          }

          // Convert scores list to a map of Map<StudentId, ScoreModel> for O(1) lookups
          Map<int, ScoreModel> studentScores = {};
          if (scoresState is AsyncData) {
             for (var score in scoresState.value!) {
                studentScores[score.studentId] = score;
             }
          }

          return ListView.separated(
             padding: const EdgeInsets.all(16),
             itemCount: students.length,
             separatorBuilder: (context, index) => const Divider(),
             itemBuilder: (context, index) {
                final student = students[index];
                final score = studentScores[student.id];
                
                // Initialize controller if it doesn't exist
                if (!_controllers.containsKey(student.id)) {
                  _controllers[student.id!] = TextEditingController(
                    text: score != null ? score.pointsEarned.toString() : '',
                  );
                }

                // If riverpod updated the score natively in the background, sync the controller cautiously
                // (Be careful not to jump the cursor if they are actively typing)
                final controller = _controllers[student.id!]!;
                if (score != null && controller.text.isEmpty) {
                   controller.text = score.pointsEarned.toString();
                }

                final focusNode = FocusNode();

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      child: Text(student.name[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Text(
                        student.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          // Save on blur
                          if (!hasFocus) {
                             final input = controller.text.trim();
                             if (input.isNotEmpty) {
                                final points = double.tryParse(input);
                                if (points != null && widget.assignment.id != null) {
                                  ref.read(scoreNotifierProvider.notifier).saveScoreForAssignment(
                                    student.id!, widget.assignment.id!, points
                                  );
                                }
                             }
                          }
                        },
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: '---',
                            filled: true,
                            fillColor: (score != null) ? Colors.green.withOpacity(0.05) : null,
                            suffixText: '/ ${widget.assignment.maxPoints.toInt()}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onSubmitted: (value) {
                             // Save on enter/next
                             if (value.isNotEmpty) {
                                final points = double.tryParse(value);
                                if (points != null && widget.assignment.id != null) {
                                  ref.read(scoreNotifierProvider.notifier).saveScoreForAssignment(
                                    student.id!, widget.assignment.id!, points
                                  );
                                }
                             }
                          },
                        ),
                      )
                    ),
                  ],
                );
             },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading roster: $e')),
      ),
    );
  }
}
