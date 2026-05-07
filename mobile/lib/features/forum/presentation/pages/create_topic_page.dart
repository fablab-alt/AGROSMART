import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/forum_bloc.dart';
import '../../domain/entities/forum_category.dart';
import '../../../../injection_container.dart' as di;

class CreateTopicPage extends StatefulWidget {
  final ForumCategory category;

  const CreateTopicPage({super.key, required this.category});

  @override
  State<CreateTopicPage> createState() => _CreateTopicPageState();
}

class _CreateTopicPageState extends State<CreateTopicPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ForumBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Nouveau Sujet"),
        ),
        body: BlocListener<ForumBloc, ForumState>(
          listener: (context, state) {
            if (state is ForumOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
              Navigator.pop(context, true); // Return true to refresh
            } else if (state is ForumError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.green.shade50,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Row(
                       children: [
                         const Icon(Icons.info_outline, color: Colors.green),
                         const SizedBox(width: 12),
                         Expanded(child: Text("Vous postez dans la catégorie : ${widget.category.name}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),
                   TextFormField(
                     controller: _titleController,
                     decoration: const InputDecoration(
                       labelText: 'Titre du sujet',
                       border: OutlineInputBorder(),
                       hintText: 'Ex: Comment lutter contre les charançons ?'
                     ),
                     validator: (v) => v!.isEmpty ? 'Requis' : null,
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                     controller: _contentController,
                     decoration: const InputDecoration(
                       labelText: 'Message',
                       border: OutlineInputBorder(),
                       hintText: 'Décrivez votre problème ou question en détail.',
                       alignLabelWithHint: true,
                     ),
                     maxLines: 6,
                     validator: (v) => v!.isEmpty ? 'Requis' : null,
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                     controller: _tagsController,
                     decoration: const InputDecoration(
                       labelText: 'Tags (séparés par des virgules)',
                       border: OutlineInputBorder(),
                       hintText: 'Ex: maïs, ravageur, urgence'
                     ),
                   ),
                   const SizedBox(height: 32),
                   SizedBox(
                     width: double.infinity,
                     child: Builder(
                       builder: (context) {
                         return ElevatedButton(
                           onPressed: () {
                             if (_formKey.currentState!.validate()) {
                               final tags = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                               context.read<ForumBloc>().add(CreateForumTopic(
                                 categoryId: widget.category.id,
                                 title: _titleController.text.trim(),
                                 content: _contentController.text.trim(),
                                 tags: tags,
                               ));
                             }
                           },
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.green,
                             foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(vertical: 16),
                           ),
                           child: const Text("PUBLIER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                         );
                       }
                     ),
                   )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
