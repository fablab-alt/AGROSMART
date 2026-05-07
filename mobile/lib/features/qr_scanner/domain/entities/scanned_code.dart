import 'package:equatable/equatable.dart';

class ScannedCode extends Equatable {
  final String code;
  final String type;
  final DateTime timestamp;

  const ScannedCode({
    required this.code,
    required this.type,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [code, type, timestamp];
}
