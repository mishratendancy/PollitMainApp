import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/pollit_theme.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _communityController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _communityController.dispose();
    _titleController.dispose();
    _descController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create a poll.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestoreService = FirestoreService();
      
      final options = _optionControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (options.length < 2) {
        throw Exception('You must provide at least 2 valid options.');
      }

      await firestoreService.createPoll(
        communitySlug: _communityController.text.trim().toLowerCase().replaceAll(' ', '-'),
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        options: options,
        uid: auth.user!.uid,
        creatorName: auth.userProfile?['displayName'] ?? auth.userProfile?['username'],
        creatorPhotoURL: auth.userProfile?['photoURL'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poll created successfully!'),
            backgroundColor: PollitColors.accent,
          ),
        );
        // Reset form
        _communityController.clear();
        _titleController.clear();
        _descController.clear();
        for (var c in _optionControllers) {
          c.clear();
        }
        setState(() {
          _optionControllers.length = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: PollitColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PollitColors.background,
      appBar: AppBar(
        backgroundColor: PollitColors.background,
        title: const Text('Create Poll'),
        surfaceTintColor: Colors.transparent,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Community', style: TextStyle(fontWeight: FontWeight.bold, color: PollitColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _communityController,
                      style: const TextStyle(color: PollitColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Technology',
                        prefixIcon: Icon(Icons.group_outlined, color: PollitColors.textMuted),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    const Text('Question', style: TextStyle(fontWeight: FontWeight.bold, color: PollitColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: PollitColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'What do you want to ask?',
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    const Text('Description (Optional)', style: TextStyle(fontWeight: FontWeight.bold, color: PollitColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      style: const TextStyle(color: PollitColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Add more context...',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 30),

                    const Text('Options', style: TextStyle(fontWeight: FontWeight.bold, color: PollitColors.textPrimary)),
                    const SizedBox(height: 12),
                    ...List.generate(_optionControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _optionControllers[index],
                                style: const TextStyle(color: PollitColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Option ${index + 1}',
                                ),
                                validator: (v) {
                                  if (index < 2 && v!.trim().isEmpty) {
                                    return 'Minimum 2 options required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            if (_optionControllers.length > 2)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: PollitColors.error),
                                onPressed: () => _removeOption(index),
                              )
                            else
                              const SizedBox(width: 48), // Spacer to align fields
                          ],
                        ),
                      );
                    }),
                    if (_optionControllers.length < 10)
                      TextButton.icon(
                        onPressed: _addOption,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Option'),
                      ),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Publish Poll'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
