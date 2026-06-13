import 'package:equatable/equatable.dart';

class CategoryRule extends Equatable {
  final String name;
  final List<String> keywords;
  final int priority;

  const CategoryRule({
    required this.name,
    required this.keywords,
    required this.priority,
  });

  @override
  List<Object?> get props => [name, keywords, priority];
}