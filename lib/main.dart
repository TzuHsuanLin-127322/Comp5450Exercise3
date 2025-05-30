import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const GamePlay(title: 'Game Page'),
    );
  }
}

class GamePlay extends StatefulWidget {
  const GamePlay({super.key, required this.title});
  final String title;

  @override
  State<GamePlay> createState() => _GamePlayState();
}

class _GamePlayState extends State<GamePlay>
    with SingleTickerProviderStateMixin {
  bool _isPaused = false;

  int _score = 0;
  double bucketX = 0.0;
  double bucketWidth = 100.0;
  double bucketHeight = 50.0;

  List<Ball> _balls = [];
  double _nextBallSpawnTime = 0.0;

  late Ticker ticker;
  Duration? _lastTickTime;
  final Random _rng = Random();

  BoxConstraints _gameAreaSize = BoxConstraints();

  @override
  void initState() {
    print('initState');
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      bucketX = (_getScreenSize().width - bucketWidth) / 2;
    });
    // TODO: Ticker, update state of ball, check for collision with bucket
    ticker = Ticker(_onTick);
    ticker.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score: $_score', style: TextStyle(fontSize: 20)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => togglePause(),
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _gameAreaSize = constraints;
                return GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(color: Colors.transparent),
                  ), // Make gesture work on all part of the map.
                  ..._renderObjects(constraints),
                ],
              ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration duration) {
    print('ticker._onTick');
    double deltaTime = 0;
    if (_lastTickTime != null) {
      deltaTime = (duration.inMilliseconds - _lastTickTime!.inMilliseconds)
          .toDouble();
    }
    setState(() {
      _updateObjectPosition();
      _updateSpawnTimer(deltaTime);
    });
    _lastTickTime = duration;
  }

  void _updateObjectPosition() {
    double screenHeight = _getScreenSize().height;
    double bucketTop = _gameAreaSize.maxHeight * 0.9;
    double bucketLeft = bucketX;
    double bucketRight = bucketX + bucketWidth;
    for (var ball in _balls) {
      ball.updatePosition();
      // TODO: Check collision with bucket, if so, remove ball add score
      double previousBallBottom = ball.previousPosition[1] + ball.size[1];
      double currentBallBottom = ball.position[1] + ball.size[1];
      bool ballBottomCrossBucketTop =
          (previousBallBottom <= bucketTop && currentBallBottom > bucketTop);
      double ballLeft = ball.position[0];
      double ballRight = ballLeft + ball.size[0];
      bool ballTouchBucketSide =
          (bucketLeft < ballRight && bucketRight > ballLeft);
      // Bucket Collision
      if (ballBottomCrossBucketTop && ballTouchBucketSide) {
        _score++;
        _balls.remove(ball);
      }
      // Ball out of screen
      if (ball.position[1] > screenHeight) {
        _balls.remove(ball);
      }
    }
  }

  void _updateSpawnTimer(double deltaTime) {
    _nextBallSpawnTime -= deltaTime;
    if (_nextBallSpawnTime <= 0) {
      _spawnBall();
      _nextBallSpawnTime =
          1000 + (_rng.nextBool() ? 1 : -1) * _rng.nextInt(300).toDouble();
    }
  }

  void _spawnBall() {
    double ballWidth = 10;
    double x = _rng.nextDouble() * (_getScreenSize().width - ballWidth);
    double speed = 1 + (_rng.nextBool() ? 1 : -1) * (_rng.nextDouble() / 2);
    _balls.add(
      Ball(Colors.black, [x, 0.05 * _getScreenSize().height], [0, speed]),
    );
  }

  List<Widget> _renderObjects(BoxConstraints constraints) {
    List<Widget> ballWidgets = _balls
        .map(
          (ball) => Positioned(
            left: ball.position[0],
            top: ball.position[1],
            child: Container(
              width: ball.size[0],
              height: ball.size[1],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ball.color,
              ),
            ),
          ),
        )
        .toList();
    Widget bucket = Positioned(
      left: bucketX,
      top: constraints.maxHeight * 0.9,
      child: Container(
        width: bucketWidth,
        height: bucketHeight,
        color: Colors.blue,
      ),
    );

    return [...ballWidgets, bucket];
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      bucketX = clampDouble(
        bucketX + details.delta.dx,
        0,
        _getScreenSize().width - bucketWidth,
      );
    });
  }

  void togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        ticker.stop();
      } else {
        ticker.start();
      }
    });
  }

  Size _getScreenSize() => MediaQuery.of(context).size;
}

class Ball {
  Color color = Colors.black;
  List<double> previousPosition = [0.0, 0.0];
  List<double> position = [0.0, 0.0];
  List<double> velocity = [0.0, 0.0];
  List<double> size = [10.0, 10.0];
  Ball(this.color, this.position, this.velocity);

  void updatePosition() {
    previousPosition[0] = position[0];
    previousPosition[1] = position[1];
    position[0] += velocity[0];
    position[1] += velocity[1];
  }
}
