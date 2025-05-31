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

enum GameState { start, play }
const int MAX_LIVES = 3;
const double BALL_SIZE = 30.0;


class _GamePlayState extends State<GamePlay>
    with SingleTickerProviderStateMixin {

  GameState _gameState = GameState.start;
  late Ticker _ticker;

  bool _isPaused = false;
  int _score = 0;
  int _lives = MAX_LIVES;
  final List<Ball> _balls = [];
  double _nextBallSpawnTime = 0.0;
  Duration? _lastTickTime;

  double bucketX = 0.0;
  double bucketWidth = 100.0;
  double bucketHeight = 50.0;

  final Random _rng = Random();

  BoxConstraints _gameAreaSize = BoxConstraints();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      bucketX = (_getScreenSize().width - bucketWidth) / 2;
    });
    // TODO: Ticker, update state of ball, check for collision with bucket
    _ticker = Ticker(_onTick);
  }

  @override
  Widget build(BuildContext context) {
    Widget body = Container();
    if (_gameState == GameState.start) {
      body = _renderStartScreen();
    } else if (_gameState == GameState.play) {
      body = _renderGameplay();
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: body,
    );
  }

  Widget _renderStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Tap to Start', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Drag horizontally to catch the ball, you lose if you miss three times', style: TextStyle(fontSize: 16)),
          SizedBox(height: 20),
          ElevatedButton(
            child: Text('Start'),
            onPressed: () => setState(() => _startGame()),
          )
        ],
      )
    );
  }

  void _startGame() {
    setState(() {
      _gameState = GameState.play;
      _isPaused = false;
      _score = 0;
      _lives = MAX_LIVES;
      _balls.clear();
      _ticker.start();
    });
  }

  Widget _renderGameplay() {
    return Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _renderLives()),
                Expanded(child: Center(child: Text('$_score', style: TextStyle(fontSize: 20)))),
                Expanded(child:  Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _togglePause(),
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    ),
                  ],
                ),)
                
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
      );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration duration) {
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
        _lives = MAX_LIVES;
        _balls.remove(ball);
      }
      // Ball out of screen
      if (ball.position[1] > _gameAreaSize.maxHeight) {
        _balls.remove(ball);
        _lives--;
        _checkGameOver();
      }
    }
  }

  void _updateSpawnTimer(double deltaTime) {
    _nextBallSpawnTime -= deltaTime;
    if (_nextBallSpawnTime <= 0.0) {
      _spawnBall();
      _nextBallSpawnTime =
          1000 + (_rng.nextBool() ? 1 : -1) * _rng.nextInt(300).toDouble();
    }
  }

  void _spawnBall() {
    double x = _rng.nextDouble() * (_getScreenSize().width - BALL_SIZE);
    double speed = 1 + (_rng.nextBool() ? 1 : -1) * (_rng.nextDouble() / 2);
    _balls.add(
      Ball(_randomColor(), [x, 0.05 * _getScreenSize().height], [0, speed], [30, 30]),
    );
  }

  Widget _renderLives() {
    return Row(
      children: _lives > 0 ? List.generate(_lives, (index) => Icon(Icons.favorite)) : [],
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
      if (_isPaused) {
        return;
      }
      bucketX = clampDouble(
        bucketX + details.delta.dx,
        0,
        _getScreenSize().width - bucketWidth,
      );
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _ticker.stop();
        _lastTickTime = null;
      } else {
        _ticker.start();
      }
    });
  }

  void _checkGameOver() {
    if (_lives > 0) {
      return;
    }
    _isPaused = true;
    _ticker.stop();
    _lastTickTime = null;
    showDialog(context: context, builder:(context) => AlertDialog(
      title: Text('Game Over'),
      content: Text('Your score is $_score'),
      actions: [
        TextButton(
          child: Text('Play Again'),
          onPressed: () {
            _resetGame();
            Navigator.of(context).pop();
          }
        ),
        TextButton(
          child: Text('Quit'),
          onPressed: () {
            _resetGame();
            _gameState = GameState.start;
            Navigator.of(context).pop();
          }
        )
      ]
    ));
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _lives = MAX_LIVES;
      _balls.clear();
      _nextBallSpawnTime = 0.0;
      _lastTickTime = null;
      _isPaused = false;
      _ticker.stop();
    });
  }

  Color _randomColor() {
    return Color.fromARGB(255, _rng.nextInt(256), _rng.nextInt(256), _rng.nextInt(256));
  }

  Size _getScreenSize() => MediaQuery.of(context).size;
}

class Ball {
  Color color = Colors.black;
  List<double> previousPosition = [0.0, 0.0];
  List<double> position = [0.0, 0.0];
  List<double> velocity = [0.0, 0.0];
  List<double> size = [BALL_SIZE, BALL_SIZE];
  Ball(this.color, this.position, this.velocity, this.size);

  void updatePosition() {
    previousPosition[0] = position[0];
    previousPosition[1] = position[1];
    position[0] += velocity[0];
    position[1] += velocity[1];
  }
}
