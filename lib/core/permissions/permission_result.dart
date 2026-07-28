import 'package:equatable/equatable.dart';

import 'permission_status.dart';
import 'permission_type.dart';

/// Result returned from the native permission layer.
class PermissionResult extends Equatable {
  const PermissionResult({required this.status, required this.permission});

  final PermissionStatus status;
  final PermissionType permission;

  bool get isGranted => status == PermissionStatus.granted;

  bool get isDenied => status == PermissionStatus.denied;

  bool get isPermanentlyDenied => status == PermissionStatus.permanentlyDenied;

  bool get isNotRequired => status == PermissionStatus.notRequired;

  bool get isRestricted => status == PermissionStatus.restricted;

  bool get isLimited => status == PermissionStatus.limited;

  @override
  List<Object> get props => [permission, status];
}
