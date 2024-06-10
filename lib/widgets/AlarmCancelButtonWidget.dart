import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PullAwayCancelWidget extends StatefulWidget {
  final VoidCallback onCancel;

  const PullAwayCancelWidget({required this.onCancel, Key? key})
      : super(key: key);

  @override
  _PullAwayCancelWidgetState createState() => _PullAwayCancelWidgetState();
}

class _PullAwayCancelWidgetState extends State<PullAwayCancelWidget>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  Offset _startPosition = Offset.zero;
  double _dragDistance = 0.0;
  double _animationSize = 0.0;
  late AnimationController _animationController;
  Color _dragColor = Colors.red;
  bool _showAnimate = true;
  bool _showReverseAnimation = false;
  double _secondaryCircleSize = 80;
  Offset _centerCoordinate = Offset.zero;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Visibility(
            visible: _showAnimate,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 80 + (_animationController.value * 70),
                  height: 80 + (_animationController.value * 70),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                );
              },
            )),
        Visibility(
            visible: _showReverseAnimation,
            child:
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                    ),
                    Container(
                      width: _secondaryCircleSize, // Adjust the size as needed
                      height: _secondaryCircleSize, // Adjust the size as needed
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                  ],
                );
              },
            )),
        GestureDetector(
          onPanStart: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset center = box.localToGlobal(box.size.center(Offset.zero));
            _centerCoordinate = center;
            _showAnimate = false;
            _showReverseAnimation = true;
            _startPosition = details.globalPosition;
            _animationController.stop(); // Stop the current animation
            setState(() {
              _scale = 1; // Increase the scale when dragging starts
              _animationSize = 100.0; // Start the expanding animation
            });
          },
          onPanUpdate: (details) {
            setState(() {
              _dragDistance =
                  (details.globalPosition - _centerCoordinate).distance;
              print(_dragDistance);
              if (_dragDistance < 40) {
                _secondaryCircleSize = 80;
              } else {
                _secondaryCircleSize = 30 + _dragDistance * 1.6;
              }
              if (_dragDistance > 125) {
                if (!_isCancelled) {
                  widget.onCancel();
                  _isCancelled = true;
                }
              }
            });
          },
          onPanEnd: (details) {
            _showAnimate = true;
            _showReverseAnimation = false;
            _secondaryCircleSize = 80;
            _animationController.repeat(); // Restart the animation
            setState(() {
              _scale = 1.0; // Increase the scale even more when dragging ends
              _dragDistance = 0.0; // Reset the drag distance
              _animationSize = 0.0; // Reset the animation size
              _dragColor = Colors.red; // Reset the drag color
            });
          },
          child: Transform.scale(
            scale: _scale,
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _dragColor, width: 2.0),
              ),
              child: const Center(
                child: Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
