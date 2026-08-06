/// Events for [WifiScanBloc].
abstract class WifiScanEvent {
  const WifiScanEvent();
}

/// Start listening to the native Wi-Fi scan stream and begin scanning.
class WifiScanStarted extends WifiScanEvent {
  const WifiScanStarted();
}

/// Stop scanning and cancel the stream subscription.
class WifiScanStopped extends WifiScanEvent {
  const WifiScanStopped();
}
