import 'package:equatable/equatable.dart';

class ForumCategory extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconName; // e.g. 'local_florist'
  final int topicCount;

  const ForumCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.topicCount,
  });

  @override
  List<Object?> get props => [id, name, description, iconName, topicCount];
}
