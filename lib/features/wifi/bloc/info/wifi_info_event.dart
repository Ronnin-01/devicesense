/// Events for [WifiInfoBloc].
sealed class WifiInfoEvent {
  const WifiInfoEvent();
}

/// Fired on page open and on pull-to-refresh.
class WifiInfoRequested extends WifiInfoEvent {
  const WifiInfoRequested();
}
