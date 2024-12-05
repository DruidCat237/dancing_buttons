import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dancing Dock',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class FallingStar extends StatefulWidget {
  final double startX;
  final Color color;
  final double angle;

  const FallingStar({
    super.key,
    required this.startX,
    required this.color,
    required this.angle,
  });

  @override
  State<FallingStar> createState() => _FallingStarState();
}

class _FallingStarState extends State<FallingStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: widget.startX + (widget.angle * 100 * _animation.value),
          top: -20 + (500 * _animation.value),
          child: Opacity(
            opacity: 1 - _animation.value,
            child: Icon(
              Icons.star,
              color: widget.color,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Please Hire Me 😊",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 40),
            AnimatedDock(
              items: [
                DockItem(icon: Icons.home, label: 'Home'),
                DockItem(icon: Icons.person, label: 'Profile'),
                DockItem(icon: Icons.message, label: 'Messages'),
                DockItem(icon: Icons.call, label: 'Calls'),
                DockItem(icon: Icons.camera, label: 'Camera'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DockItem {
  final IconData icon;
  final String label;

  const DockItem({required this.icon, required this.label});
}

class AnimatedDock extends StatefulWidget {
  final List<DockItem> items;

  const AnimatedDock({
    super.key,
    required this.items,
  });

  @override
  State<AnimatedDock> createState() => _AnimatedDockState();
}

class _AnimatedDockState extends State<AnimatedDock>
    with TickerProviderStateMixin {
  late List<DockItem> _items;
  int? _hoveredIndex;
  bool _isDancing = false;
  List<Widget> _stars = [];
  late final AnimationController _danceController;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _danceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _danceController.dispose();
    super.dispose();
  }

  void _createStars() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
    ];

    setState(() {
      _stars = List.generate(5, (index) {
        return FallingStar(
          key: UniqueKey(),
          startX: _random.nextDouble() * 200 + 100,
          color: colors[index % colors.length],
          angle: _random.nextDouble() * 2 - 1,
        );
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _stars = [];
          });
        }
      });
    });
  }

  void _startDancing() {
    setState(() {
      _isDancing = !_isDancing;
    });

    if (_isDancing) {
      _danceController.repeat(reverse: true);
      _createStars();
    } else {
      _danceController.stop();
      _danceController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildDraggableItem(item, index);
              }),
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: _startDancing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDancing ? Colors.red : Colors.blue,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._stars,
      ],
    );
  }

  Widget _buildDraggableItem(DockItem item, int index) {
    return Draggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: _buildIcon(item, index, true),
      ),
      childWhenDragging: _buildIcon(item, index, false, opacity: 0.3),
      child: DragTarget<int>(
        onWillAccept: (data) => data != null && data != index,
        onAccept: (draggedIndex) {
          setState(() {
            final draggedItem = _items[draggedIndex];
            _items.removeAt(draggedIndex);
            _items.insert(index, draggedItem);
          });
        },
        builder: (context, candidateData, rejectedData) {
          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredIndex = index),
            onExit: (_) => setState(() => _hoveredIndex = null),
            child: _buildIcon(item, index, false),
          );
        },
      ),
    );
  }

  Widget _buildIcon(DockItem item, int index, bool isDragging,
      {double opacity = 1.0}) {
    final isHovered = _hoveredIndex == index;
    final scale = isHovered ? 1.2 : 1.0;

    return AnimatedBuilder(
      animation: _danceController,
      builder: (context, child) {
        double rotation = 0.0;
        if (_isDancing) {
          rotation = math.sin(_danceController.value * math.pi * 2) * 0.1;
        }

        return Transform.rotate(
          angle: rotation,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 200),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.primaries[index % Colors.primaries.length],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isHovered || isDragging
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Tooltip(
                  message: item.label,
                  child: Icon(
                    item.icon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
