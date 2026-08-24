import 'package:bagyesrushappusernew/features/report/domain/entities/report.dart';

/// Sealed states for the "My Reports" list.
sealed class MyReportsState {
  const MyReportsState();
}

class MyReportsLoading extends MyReportsState {
  const MyReportsLoading();
}

class MyReportsLoaded extends MyReportsState {
  final List<Report> reports;
  const MyReportsLoaded({required this.reports});
}

class MyReportsError extends MyReportsState {
  final String message;
  const MyReportsError({required this.message});
}
