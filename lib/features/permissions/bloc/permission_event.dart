import 'package:equatable/equatable.dart';

import '../../../../core/permissions/permission_type.dart';

sealed class PermissionEvent extends Equatable {
  const PermissionEvent();

  @override
  List<Object?> get props => [];
}

/// Checks the current permission status.
final class PermissionChecked extends PermissionEvent {
  const PermissionChecked(this.permission);

  final PermissionType permission;

  @override
  List<Object?> get props => [permission];
}

/// Requests the permission from Android.
final class PermissionRequested extends PermissionEvent {
  const PermissionRequested(this.permission);

  final PermissionType permission;

  @override
  List<Object?> get props => [permission];
}

/// Opens Android App Settings.
final class PermissionSettingsOpened extends PermissionEvent {
  const PermissionSettingsOpened();
}
