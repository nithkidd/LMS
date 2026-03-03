import 'package:flutter/material.dart';

class AddClassDialog extends StatefulWidget {
  final void Function(
    String name,
    String year,
    bool isAdviser,
    List<String> subjects,
  )
  onSubmit;

  const AddClassDialog({Key? key, required this.onSubmit}) : super(key: key);

  /// Convenience method to show the dialog.
  static void show(
    BuildContext context,
    void Function(
      String name,
      String year,
      bool isAdviser,
      List<String> subjects,
    )
    onSubmit,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddClassDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<AddClassDialog> {
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _subjectsController = TextEditingController();
  bool _isAdviser = false;

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _subjectsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('បន្ថែមថ្នាក់'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'ឈ្មោះថ្នាក់'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(
              labelText: 'ឆ្នាំសិក្សា (ឧ. ២០២៤-២០២៥)',
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('ខ្ញុំជាគ្រូបន្ទុកថ្នាក់នេះ'),
            value: _isAdviser,
            onChanged: (val) {
              setState(() {
                _isAdviser = val ?? false;
              });
            },
          ),
          if (_isAdviser) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _subjectsController,
              decoration: const InputDecoration(
                labelText: 'មុខវិជ្ជា',
                hintText: 'ឧ. គណិតវិទ្យា, រូបវិទ្យា',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('បោះបង់'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final year = _yearController.text.trim();

            if (name.isNotEmpty && year.isNotEmpty) {
              List<String> subjects = [];
              if (_isAdviser && _subjectsController.text.trim().isNotEmpty) {
                subjects = _subjectsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
              }
              widget.onSubmit(name, year, _isAdviser, subjects);
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('សូមបំពេញគ្រប់វាលទាំងអស់')),
              );
            }
          },
          child: const Text('បន្ថែម'),
        ),
      ],
    );
  }
}
