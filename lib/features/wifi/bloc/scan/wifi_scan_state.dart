import 'package:equatable/equatable.dart';

import '../../models/wifi_scan_snapshot.dart';

/// States for [WifiScanBloc].
sealed class WifiScanState extends Equatable {
  const WifiScanState();

  @override
  List<Object?> get props => [];
}

/// Default state before scanning has ever been requested.
class WifiScanInitial extends WifiScanState {
  const WifiScanInitial();
}

/// Stream subscription opened, waiting for the first event from native.
class WifiScanLoading extends WifiScanState {
  const WifiScanLoading();
}

/// At least one snapshot received from the repository.
class WifiScanLoaded extends WifiScanState {
  const WifiScanLoaded(this.snapshot);

  final WifiScanSnapshot snapshot;

  @override
  List<Object?> get props => [snapshot];
}

/// The native side reported a scan error (permission denied, location
/// off, Wi-Fi off, etc.) — the error message carries the code prefix
/// set by [WifiScanRepository._emitError]: "CODE: message".
class WifiScanError extends WifiScanState {
  const WifiScanError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
