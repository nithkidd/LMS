import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gradebook/providers/score_provider.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  final int studentId;
  final String studentName;

  const StudentProfileScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch scores directly via Riverpod when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scoreNotifierProvider.notifier).loadScoresForStudent(widget.studentId);
    });
  }

  void _showAddScoreDialog(BuildContext context) {
    final assignmentController = TextEditingController();
    final pointsController = TextEditingController();
    final maxPointsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Score', style: TextStyle(fontSize: 24)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: assignmentController,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Name',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Midterm Exam',
                  ),
                  style: const TextStyle(fontSize: 18),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pointsController,
                        decoration: const InputDecoration(
                          labelText: 'Points Earned',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('/', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: maxPointsController,
                        decoration: const InputDecoration(
                          labelText: 'Max Points',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                final assignment = assignmentController.text.trim();
                final points = double.tryParse(pointsController.text.trim());
                final max = double.tryParse(maxPointsController.text.trim());
                
                if (assignment.isNotEmpty && points != null && max != null && max > 0) {
                  ref.read(scoreNotifierProvider.notifier).addScore(
                    widget.studentId, assignment, points, max
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please check your inputs ensure max points > 0', style: TextStyle(fontSize: 16)),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Score', style: TextStyle(fontSize: 18)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoreState = ref.watch(scoreNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName}\'s Profile'),
      ),
      body: scoreState.when(
        data: (data) {
          final scores = data.scores;
          final average = data.averagePercentage;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Large high-contrast grade banner
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Overall Grade',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${average.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: _getGradeColor(average, context),
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showAddScoreDialog(context),
                  icon: const Icon(Icons.post_add, size: 28),
                  label: const Text(
                    'Add New Score',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Assignment History',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),

              Expanded(
                child: scores.isEmpty
                    ? const Center(
                        child: Text(
                          'No scores recorded yet.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: scores.length,
                        itemBuilder: (context, index) {
                          final score = scores[index];
                          final percentage = (score.pointsEarned / score.maxPoints) * 100;
                          
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                minVerticalPadding: 12,
                                title: Text(
                                  score.assignmentName,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${score.pointsEarned.toStringAsFixed(1)} / ${score.maxPoints.toStringAsFixed(1)} points',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(percentage, context).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getGradeColor(percentage, context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: const TextStyle(fontSize: 18, color: Colors.red)),
        ),
      ),
    );
  }

  // Helper method for accessibility: Color coding grades
  Color _getGradeColor(double percentage, BuildContext context) {
    if (percentage >= 90) return Colors.green.shade700;
    if (percentage >= 80) return Colors.blue.shade700;
    if (percentage >= 70) return Colors.orange.shade700;
    if (percentage > 0) return Colors.red.shade700;
    return Theme.of(context).colorScheme.onPrimaryContainer; // Default neutral for 0%
  }
}
