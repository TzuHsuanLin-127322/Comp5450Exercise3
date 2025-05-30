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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const GamePlay(title: 'Game Page'),
    );
  }
}

class GamePlay extends StatefulWidget {
  const GamePlay({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<GamePlay> createState() => _GamePlayState();
}

class _GamePlayState extends State<GamePlay>
    with SingleTickerProviderStateMixin {
  int _score = 0;
  // TODO: Lock bucket y position, and change x position based on input
  double bucketX = 0.0;
  double bucketWidth = 100.0;
  double bucketHeight = 10.0;

  // TODO: Ball list to remember the state of all the balls
  // TODO: Timers to create ball
  // TODO: Add ticker for ball movement
  List<Ball> _balls = [];
  late Timer _ballSpawnTimer;
  late Ticker ticker;

  final Random _rng = Random();

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
    // Randomize ball spawn
    _createNextSpawnTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Row(children: [Text('Score: $_score')]),
          Expanded(child: 
            GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            child: Stack(
              children: [
                Positioned.fill(child: Container(color: Colors.transparent)),
                ..._renderObjects(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ballSpawnTimer.cancel();
    ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration duration) {
    print('ticker._onTick');
    setState(() {
      for (var ball in _balls) {
        ball.updatePosition();
        // TODO: Check collision with bucket, if so, remove ball add score
        // TODO: Check if ball is out of bounds, if so, remove ball
        if (ball.position[1] > _getScreenSize().height) {
          _balls.remove(ball);
        }
      }
    });
  }

  void _createNextSpawnTimer() {
    int nextTime = 1000 + (_rng.nextBool() ? 1 : -1) * _rng.nextInt(300);
    _ballSpawnTimer = Timer(Duration(milliseconds: nextTime), _onSpawnTimer);
  }

  void _onSpawnTimer() {
    print('ballSpawnTimer');
    setState(() {
      double ballWidth = 10;
      double x = _rng.nextDouble() * (_getScreenSize().width - ballWidth);
      double speed = 1 + (_rng.nextBool() ? 1 : -1) * (_rng.nextDouble() / 2);
      _balls.add(
        Ball(Colors.black, [x, 0.05 * _getScreenSize().height], [0, speed]),
      );
    });
    _createNextSpawnTimer();
  }

  List<Widget> _renderObjects() {
    List<Widget> ballWidgets = _balls
        .map(
          (ball) => Positioned(
            left: ball.position[0],
            top: ball.position[1],
            child: Container(
              width: 10,
              height: 10,
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
      top: _getScreenSize().height * 0.9,
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
      bucketX = clampDouble(bucketX + details.delta.dx, 0, _getScreenSize().width - bucketWidth);
    });
  }

  Size _getScreenSize() => MediaQuery.of(context).size;
}

class Ball {
  Color color = Colors.black;
  List<double> position = [0.0, 0.0];
  List<double> velocity = [0.0, 0.0];
  Ball(this.color, this.position, this.velocity);

  void updatePosition() {
    position[0] += velocity[0];
    position[1] += velocity[1];
  }
}
