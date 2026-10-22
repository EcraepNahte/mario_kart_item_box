import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:mario_kart_item_box/services/gpio_service.dart';

class ItemBoxView extends StatefulWidget {
  const ItemBoxView({super.key});

  @override
  State<ItemBoxView> createState() => _ItemBoxViewState();
}

class _ItemBoxViewState extends State<ItemBoxView> {
  List<String> itemStrings = [
    'assets/Banana_-_Mario_Kart_Wii.webp',
    'assets/Coin_-_Mario_Kart_Wii.webp',
    'assets/Green_Shell_Artwork_-_Mario_Kart_Wii.webp',
  ];
  int _currentIndex = 0;
  bool _isSpinning = false;
  int _millisecondsElapsed = 0;
  Timer? _timer;
  late AudioSource sound;

  void configureSoLoud() async {
    await SoLoud.instance.init();

    sound = await SoLoud.instance.loadAsset(
      'assets/mario-kart-wii-item-box.mp3',
    );
  }

  Future<void> randomizeItems() async {
    if (_isSpinning) return;

    SoLoud.instance.play(sound);

    _timer?.cancel();

    setState(() {
      _millisecondsElapsed = 0;
      _isSpinning = true;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
      setState(() {
        _millisecondsElapsed += 100;
        _currentIndex = (_currentIndex + 1) % itemStrings.length;
      });

      if (_millisecondsElapsed >= 3700) {
        _timer?.cancel();
        setState(() {
          _isSpinning = false;
          _currentIndex = Random().nextInt(itemStrings.length);
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();

    configureSoLoud();

    GpioService().init();
    GpioService().listenToPhysicalButton(4, randomizeItems);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.blue,
      child: Column(
        children: [
          SizedBox(
            width: 500,
            height: 500,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: Image(image: AssetImage(itemStrings[_currentIndex])),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: randomizeItems,
            child: const Text('Shuffle Items'),
          ),
        ],
      ),
    );
  }
}
