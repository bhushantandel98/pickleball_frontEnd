import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';

/// Modal dialog allowing the author of a post to edit its text content.
class EditPostDialog extends StatefulWidget {
  final String postId;
  final String initialContent;
  final void Function(String newContent) onSave;

  const EditPostDialog({
    super.key,
    required this.postId,
    required this.initialContent,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String postId,
    required String initialContent,
    required void Function(String newContent) onSave,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => EditPostDialog(
        postId: postId,
        initialContent: initialContent,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<EditPostDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(_controller.text.trim());
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Post'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _controller,
              label: 'Post caption',
              hint: 'What is on your mind?',
              maxLines: 4,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Post content cannot be empty';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        AppButton.outline(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          label: 'Save Changes',
          onPressed: _handleSave,
        ),
      ],
    );
  }
}
