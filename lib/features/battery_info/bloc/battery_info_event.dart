part of 'battery_info_bloc.dart';

sealed class BatteryInfoEvent {
  const BatteryInfoEvent();
}

/// Fired on first page load and on pull-to-refresh.
class BatteryInfoRequested extends BatteryInfoEvent {
  const BatteryInfoRequested();
}
