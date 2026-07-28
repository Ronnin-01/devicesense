import 'package:equatable/equatable.dart';

import '../../../../core/permissions/permission_result.dart';

sealed class PermissionState extends Equatable {
  const PermissionState();

  @override
  List<Object?> get props => [];
}

final class PermissionInitial extends PermissionState {
  const PermissionInitial();
}

final class PermissionLoading extends PermissionState {
  const PermissionLoading();
}

final class PermissionLoaded extends PermissionState {
  const PermissionLoaded(this.result);

  final PermissionResult result;

  @override
  List<Object?> get props => [result];
}

final class PermissionError extends PermissionState {
  const PermissionError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
