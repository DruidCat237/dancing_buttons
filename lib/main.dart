import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// Recruitment task to do macOS-style dock implementation with
/// smooth animations and interactive elements.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DancingButtons',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

/// The main UI featuring an interactive dock implementation.
///
/// Displays a message and hosts the [MacOSDock] main widget.
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 252, 252),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Please Hire Me 🙂",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            MacOSDock(
              items: [
                DockItemData(
                  icon: Icons.home,
                  label: 'Home',
                  description: 'Home screen',
                  color: const Color(0xFFFF5722),
                ),
                DockItemData(
                  icon: Icons.person,
                  label: 'Profile',
                  description: 'Profile settings',
                  color: const Color(0xFFFFEB3B),
                ),
                DockItemData(
                  icon: Icons.message,
                  label: 'Messages',
                  description: 'messages',
                  color: const Color(0xFFE91E63),
                ),
                DockItemData(
                  icon: Icons.call,
                  label: 'Calls',
                  description: 'just calls',
                  color: const Color(0xFFFF5722),
                ),
                DockItemData(
                  icon: Icons.camera,
                  label: 'Camera',
                  description: 'Take a selfie',
                  color: const Color(0xFF009688),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Important The above code snippet contains closing patterns that properly
/// terminate various Flutter widgets, such as Column, Positioned, and Scaffold
/// I choose Scaffold widget for tooltips as basic layout of Material Design
/// because its the best for ui.
/// Data class representing an individual dock item.
///
/// Contains all necessary information for displaying and describing
/// a dock item, including its visual properties and metadata.
class DockItemData {
  /// The icon to display in the dock item.
  final IconData icon;

  /// The label shown below the dock item.
  final String label;

  /// A longer description shown in the tooltip.
  final String description;

  /// The background color of the dock item.
  final Color color;

  const DockItemData({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}

/// A widget implementing a dock with interactive features.
///
/// Features include:
/// * Dynamic item scaling on hover
/// * Smooth animations
/// * Drag-and-drop reordering like in macOS dock
/// * Tooltips with descriptions
class MacOSDock extends StatefulWidget {
  /// The items to display in the dock.
  final List<DockItemData> items;

  const MacOSDock({
    super.key,
    required this.items,
  });

  @override
  State<MacOSDock> createState() => _MacOSDockState();
}

class _MacOSDockState extends State<MacOSDock> with TickerProviderStateMixin {
  /// Base size for dock items
  static const double itemSize = 56.0;

  /// Spacing between dock items, proportional to item size
  static const double itemSpacing = itemSize * 1.3;

  /// Current drag position in the dock
  Offset? _dragPosition;

  /// List of dock items that can be modified during runtime
  late List<DockItemData> _items;

  /// Index of the currently hovered item
  int? _hoveredIndex;

  /// Index of the currently dragged item
  int? _draggedIndex;

  /// Whether the dragged item is outside the dock area
  bool _isDraggingOutside = false;

  /// Maps item indices to their current positions
  Map<int, int> _itemSlotMap = {};

  /// Prevents rapid consecutive swaps
  /// that was one of my first issues
  bool _isSwapping = false;

  /// Tracks the last swap time for throttling
  DateTime? _lastSwapTime;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _initializeItemSlotMap();
  }

  /// Sets up starting positions for all dock items.
  void _initializeItemSlotMap() {
    _itemSlotMap = {};
    for (int i = 0; i < _items.length; i++) {
      _itemSlotMap[i] = i;
    }
  }

  /// Calculates the scale factor for an item based on its position.
  double _getScale(int index) {
    if (_hoveredIndex == null && _draggedIndex == null) return 1.0;

    int currentIndex = _draggedIndex ?? _hoveredIndex!;

    if (index == currentIndex) {
      return 1.2;
    } else if ((currentIndex > 0 && index == currentIndex - 1) ||
        (currentIndex < _items.length - 1 && index == currentIndex + 1)) {
      return 1.1;
    }
    return 1.0;
  }

  /// Determines the horizontal position for an item in the dock.
  double _calculateSlotPosition(int slotIndex, BoxConstraints constraints) {
    final double dockWidth = constraints.maxWidth;
    final double startOffset =
        (dockWidth - ((_items.length - 1) * itemSpacing + itemSize)) / 2;
    return startOffset + slotIndex * itemSpacing;
  }

  /// Retrieves the item data according to slot position.
  DockItemData _getItemAtSlot(int slot) {
    int itemIndex = 0;
    for (var entry in _itemSlotMap.entries) {
      if (entry.value == slot) {
        itemIndex = entry.key;
        break;
      }
    }
    return _items[itemIndex];
  }

  /// Validates that each slot has exactly one item assigned to prevent issues.
  bool _validateSlotMap(Map<int, int> slotMap) {
    Set<int> usedSlots = {};
    for (int slot in slotMap.values) {
      if (!usedSlots.add(slot)) return false;
    }
    return usedSlots.length == _items.length;
  }

  /// Determines if a position is within the dock's active area.
  /// I added this because while testing UX there was a lot of issues
  /// with wrong positioning outside the dock.
  bool _isWithinDockArea(Offset position, BoxConstraints constraints) {
    final double dockWidth = (_items.length - 1) * itemSpacing + itemSize;
    final double dockStart = (constraints.maxWidth - dockWidth) / 2;
    final double dockEnd = dockStart + dockWidth;

    return position.dx >= dockStart - itemSize * 2 &&
        position.dx <= dockEnd + itemSize * 2 &&
        position.dy >= -100 &&
        position.dy <= 100;
  }

  /// Resets all drag-related state variables.
  void _resetDragState() {
    setState(() {
      _draggedIndex = null;
      _isDraggingOutside = false;
      _dragPosition = null;
    });
  }

// This is our helper that makes icons look fancy when we drag them around.
// It takes the regular icon, scales it up a bit (1.05 times), and adds
// the dragging effect. Basically makes the icon float and look more
// interactive when you move it around - gives nice visual feedback
  Widget _buildIcon(DockItemData item, double scale, bool isDragging) {
    return Transform.scale(
      scale: scale,
      child: _buildIconBase(item, isDragging: isDragging),
    );
  }

// Creates squared boxes
// with rounded corners.
  Widget _buildIconBase(DockItemData item, {bool isDragging = false}) {
    return Container(
      width: itemSize,
      height: itemSize,
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDragging ? Colors.black38 : Colors.black12,
            blurRadius: isDragging ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        item.icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  /// Builds an individual dock item with animations and interactions.
  /// // - Position calculation (that smooth sliding when reordering)
// - Mouse interactions (hovering makes it pop up slightly)
// - Drag and drop (all that complex logic for swapping items)
//
// The AnimatedPositioned widget I set as 200ms because
// it feels responsive but not too quick
  Widget _buildDockItem(
    DockItemData item,
    int index,
    BoxConstraints constraints,
  ) {
    final isDraggedItem = index == _draggedIndex;
    int targetSlot = _itemSlotMap[index] ?? index;

    if (_isDraggingOutside && !isDraggedItem && targetSlot > _draggedIndex!) {
      targetSlot--;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      left: _calculateSlotPosition(targetSlot, constraints),
      bottom: 10,
      child: MouseRegion(
        onEnter: (_) {
          if (!_isDraggingOutside) {
            setState(() => _hoveredIndex = targetSlot);
          }
        },
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: Draggable<int>(
          data: index,
          feedback: _buildIcon(item, 1.05, true),
          childWhenDragging: SizedBox(
            width: itemSize,
            height: itemSize,
          ),
          onDragStarted: () => setState(() {
            _draggedIndex = index;
            _isDraggingOutside = false;
            _hoveredIndex = index;
            _initializeItemSlotMap();
          }),

// onDragUpdate it handles all the math for
// dragging items. We need to:
// 1. Figure out exactly where the mouse is relative to our dock
// 2. Calculate if we're still over the dock or dragged too far
// 3. Work out which slot we're closest to
// 4. Handle all the swapping logic with delays to prevent it feeling
//    too fast.
// The main trick that i found in internet is that
// the position calculations use the center of the dock as reference,
// which makes items distribute evenly on both sides
          onDragUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset localPosition =
                box.globalToLocal(details.globalPosition);
            final double dockWidth =
                (_items.length - 1) * itemSpacing + itemSize;
            final bool wasOutside = _isDraggingOutside;

            setState(() {
              _dragPosition = localPosition;
              bool isNowOutside =
                  !_isWithinDockArea(localPosition, constraints);

              if (wasOutside && !isNowOutside) {
                _initializeItemSlotMap();
                _hoveredIndex = _draggedIndex;
                _isDraggingOutside = false;
                return;
              }

              _isDraggingOutside = isNowOutside;

              if (!_isDraggingOutside) {
                final double dockStart = (constraints.maxWidth - dockWidth) / 2;
                double boundedDragX =
                    localPosition.dx.clamp(dockStart, dockStart + dockWidth);
                double relativePosition = boundedDragX - dockStart;

                int currentSlot = _itemSlotMap[_draggedIndex!]!;
                double exactSlot = relativePosition / itemSpacing;
                int newSlot = exactSlot.round().clamp(0, _items.length - 1);

                if (newSlot != currentSlot) {
                  final now = DateTime.now();
                  if (_lastSwapTime != null &&
                      now.difference(_lastSwapTime!) <
                          const Duration(milliseconds: 150)) {
                    return;
                  }
                  _lastSwapTime = now;

                  if (!_isSwapping) {
                    _isSwapping = true;
                    Map<int, int> newSlots = Map<int, int>.from(_itemSlotMap);
                    int? itemToSwap;

                    for (var entry in _itemSlotMap.entries) {
                      if (entry.value == newSlot &&
                          entry.key != _draggedIndex) {
                        itemToSwap = entry.key;
                        break;
                      }
                    }

                    if (itemToSwap != null) {
                      newSlots[itemToSwap] = currentSlot;
                      newSlots[_draggedIndex!] = newSlot;

                      if (_validateSlotMap(newSlots)) {
                        _itemSlotMap = newSlots;
                        _hoveredIndex = newSlot;
                      }
                    }

                    Future.delayed(const Duration(milliseconds: 100), () {
                      _isSwapping = false;
                    });
                  }
                }
              }
            });
          },
          onDraggableCanceled: (_, __) => _resetDragState(),
          onDragEnd: (details) {
            if (_draggedIndex == null) return;

            final List<DockItemData> newItems =
                List.filled(_items.length, _items[0]);
            _itemSlotMap.forEach((index, slot) {
              newItems[slot] = _items[index];
            });

            setState(() {
              _items = newItems;
              _draggedIndex = null;
              _isDraggingOutside = false;
              _dragPosition = null;
              _itemSlotMap.clear();
              for (int i = 0; i < _items.length; i++) {
                _itemSlotMap[i] = i;
              }
            });
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 1.0,
              end: _getScale(targetSlot),
            ),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Transform.translate(
                offset: Offset(0, -(scale - 1.0) * 15),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              );
            },
            child: _buildIconBase(item),
          ),
        ),
      ),
    );
  }

  /// This is the main builder for our dock - it constructs the whole visual interface.
  /// I'm using LayoutBuilder because we need to know exactly how much space we have
  /// to work with for positioning everything perfectly.
  ///
  ///
  /// Layer 1 (Bottom):
  /// - A semi-transparent black bar (0.2 opacity looks subtle enough)
  /// - Rounded corners (30px radius) to make it feel modern
  /// - 10px padding top and bottom to give items some breathing room
  /// - Fixed height of 70px - found this to be the sweet spot for usability
  ///
  /// Layer 2 (Middle):
  /// - All our dock items, built using _buildDockItem
  /// - They can overlap thanks to Stack with clipBehavior: Clip.none
  /// - Each item gets its index and data mapped from our _items list
  ///
  /// Layer 3 (Top):
  /// - The tooltip that appears when hovering (positioned 35px above the item)
  /// - Only shows up when we're hovering AND not dragging
  /// - Fades in smoothly over 200ms
  /// - Dark background (black87) with rounded corners (8px)
  /// - Text is small
  ///
  /// The clipBehavior is set to Clip.none everywhere because our items and tooltip
  /// need to be able to expand outside their containers for the hover animations
  /// and positioning to work properly.
  ///
  /// The Center widget ensures everything stays in the middle of the screen,
  /// while constraints.maxWidth makes sure our dock spans the available space.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Container(
                width: constraints.maxWidth,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SizedBox(
                  height: 70,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: _items.asMap().entries.map((entry) {
                      return _buildDockItem(
                          entry.value, entry.key, constraints);
                    }).toList(),
                  ),
                ),
              ),
            ),
            if (_hoveredIndex != null && !_isDraggingOutside)
              Positioned(
                top: -35,
                left: _calculateSlotPosition(_hoveredIndex!, constraints) +
                    (itemSize - 100) / 2,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getItemAtSlot(_hoveredIndex!).description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
