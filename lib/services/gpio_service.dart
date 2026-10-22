import 'dart:async';
import 'package:flutter_gpiod/flutter_gpiod.dart';

class GpioService {
  static final GpioService _instance = GpioService._internal();
  factory GpioService() => _instance;
  GpioService._internal();

  GpioChip? _chip;
  final Map<int, GpioLine> _activeLines = {};

  final StreamController<MapEntry<int, bool>> _buttonStreamController =
      StreamController<MapEntry<int, bool>>.broadcast();

  Stream<MapEntry<int, bool>> get buttonEvents =>
      _buttonStreamController.stream;

  void init() {
    try {
      final chips = FlutterGpiod.instance.chips;
      for (var chip in chips.values) {
        if (chip.label.contains('bcm') || chip.label.contains('rp1')) {
          _chip = chip;
          break;
        }
      }
    } catch (e) {
      print("GPIO Initialization failed: $e");
    }
  }

  void listenToPhysicalButton(
    int pinNumber,
    Future<void> Function() asyncAction,
  ) async {
    if (_chip == null) return;

    try {
      if (!_activeLines.containsKey(pinNumber)) {
        final line = _chip!.lines[pinNumber];

        line.requestInput(
          consumer: 'flutter_button_input',
          triggers: {SignalEdge.falling},
        );

        _activeLines[pinNumber] = line;

        bool isBusy = false;

        line.onEvent.listen((SignalEvent event) async {
          if (event.edge == SignalEdge.falling && !isBusy) {
            isBusy = true;

            try {
              await asyncAction();
            } catch (e) {
              print("Error during GPIO action: $e");
            } finally {
              isBusy =
                  false; // Unlock only after the action finishes completely
            }
          }
        });
      }
    } catch (e) {
      print("Failed to setup button on pin $pinNumber: $e");
    }
  }

  void dispose() {
    for (var line in _activeLines.values) {
      line.release();
    }
    _activeLines.clear();
    _buttonStreamController.close();
  }
}
