import 'dart:async';

import '../../../core/platform/bluetooth_discovery_channel.dart';
import '../models/bluetooth_device_model.dart';

class BluetoothDiscoveryController {
  final Map<String, BluetoothDeviceModel> _devices = {};

  StreamSubscription? _subscription;

  Stream<List<BluetoothDeviceModel>> get devices async* {
    yield _devices.values.toList();
  }

  final StreamController<List<BluetoothDeviceModel>> _controller =
      StreamController.broadcast();

  Stream<List<BluetoothDeviceModel>> get stream => _controller.stream;

  void start() {
    _subscription = BluetoothDiscoveryChannel.events.listen((event) {
      if (event["event"] == "deviceUpdate") {
        final device = BluetoothDeviceModel.fromJson(event["device"]);

        _devices[device.address] = device;

        _controller.add(_devices.values.toList());
      }
    });
  }

  void dispose() {
    _subscription?.cancel();

    _controller.close();
  }
}
