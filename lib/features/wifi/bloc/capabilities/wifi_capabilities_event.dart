/// Events for [WifiCapabilitiesBloc].
sealed class WifiCapabilitiesEvent {
  const WifiCapabilitiesEvent();
}

/// Fired on page open and on pull-to-refresh.
class WifiCapabilitiesRequested extends WifiCapabilitiesEvent {
  const WifiCapabilitiesRequested();
}
