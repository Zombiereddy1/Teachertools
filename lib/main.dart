import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const TeacherProApp());
}

// ==========================================
// 1. APP SETUP & THEME
// ==========================================

class TeacherProApp extends StatelessWidget {
  const TeacherProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Teacher Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212), // Deep OLED Black
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.pinkAccent,
        ),
      ),
      home: const Whiteboard(),
    );
  }
}

// ==========================================
// 2. MAIN INTERFACE (CANVAS + TOOLS)
// ==========================================

class Whiteboard extends StatefulWidget {
  const Whiteboard({super.key});

  @override
  State<Whiteboard> createState() => _WhiteboardState();
}

enum ToolType { pen, marker, eraser, rect, circle, cube }

class _WhiteboardState extends State<Whiteboard> {
  // --- STATE VARIABLES ---
  List<SketchObject> objects = [];
  SketchObject? currentObject;
  
  // Tool Settings
  ToolType selectedTool = ToolType.pen;
  Color selectedColor = Colors.white;
  double strokeWidth = 4.0;
  Offset menuPos = const Offset(20, 100);
  bool isMenuCollapsed = false;

  // Color Picker State
  double hueValue = 0.0; // 0 to 360

  // --- GESTURE HANDLERS ---

  void _onPanStart(DragStartDetails details) {
    final pt = details.localPosition;
    
    if (selectedTool == ToolType.rect || selectedTool == ToolType.circle || selectedTool == ToolType.cube) {
      // Start a Shape
      setState(() {
        currentObject = ShapeObject(selectedTool, pt, pt, selectedColor, strokeWidth);
      });
    } else {
      // Start a Stroke (Pen/Marker/Eraser)
      setState(() {
        bool isEraser = selectedTool == ToolType.eraser;
        Color color = selectedTool == ToolType.marker 
            ? selectedColor.withOpacity(0.5) 
            : (isEraser ? Colors.black : selectedColor);
            
        currentObject = StrokeObject(
          [Point(pt, DateTime.now())], 
          color, 
          isEraser ? 30.0 : strokeWidth,
          isEraser
        );
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (currentObject == null) return;
    final pt = details.localPosition;

    setState(() {
      if (currentObject is ShapeObject) {
        // Update Shape Size
        (currentObject as ShapeObject).endPoint = pt;
      } else if (currentObject is StrokeObject) {
        // Add point to stroke
        (currentObject as StrokeObject).points.add(Point(pt, DateTime.now()));
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (currentObject != null) {
      setState(() {
        objects.add(currentObject!);
        currentObject = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // LAYER 1: The Drawing Canvas
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              painter: MasterPainter(objects, currentObject),
              size: Size.infinite,
            ),
          ),

          // LAYER 2: Floating Advanced Toolbar
          Positioned(
            left: menuPos.dx,
            top: menuPos.dy,
            child: Draggable(
              feedback: _buildGlassMenu(isDragging: true),
              childWhenDragging: Container(),
              onDraggableCanceled: (_, offset) => setState(() => menuPos = offset),
              child: _buildGlassMenu(isDragging: false),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. PREMIUM GLASS UI ---

  Widget _buildGlassMenu({required bool isDragging}) {
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isMenuCollapsed ? 60 : 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF252525).withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
          boxShadow: [
             BoxShadow(color: Colors.black54, blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: isMenuCollapsed 
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.white), 
              onPressed: () => setState(() => isMenuCollapsed = false))
          : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Collapse
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TEACHER PRO", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  IconButton(
                    icon: const Icon(Icons.close_fullscreen, size: 18, color: Colors.grey), 
                    onPressed: () => setState(() => isMenuCollapsed = true))
                ],
              ),
              const Divider(color: Colors.white12),
              
              // Section 1: Tools Grid
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _toolBtn(Icons.edit, ToolType.pen),
                  _toolBtn(Icons.format_paint, ToolType.marker),
                  _toolBtn(Icons.crop_square, ToolType.rect),
                  _toolBtn(Icons.circle_outlined, ToolType.circle),
                  _toolBtn(Icons.view_in_ar, ToolType.cube), // 3D CUBE
                  _toolBtn(Icons.cleaning_services, ToolType.eraser),
                ],
              ),
              const SizedBox(height: 15),

              // Section 2: Advanced Color Picker (Hue Slider)
              const Text("COLOR SPECTRUM", style: TextStyle(color: Colors.grey, fontSize: 10)),
              const SizedBox(height: 8),
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    hueValue = (hueValue + details.delta.dx).clamp(0.0, 360.0);
                    selectedColor = HSVColor.fromAHSV(1.0, hueValue, 1.0, 1.0).toColor();
                    if(selectedTool == ToolType.eraser) selectedTool = ToolType.pen;
                  });
                },
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.red, Colors.yellow, Colors.green, 
                        Colors.cyan, Colors.blue, Colors.purple, Colors.red
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment((hueValue / 180.0) - 1.0, 0),
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              // Section 3: Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text("CLEAR", style: TextStyle(color: Colors.red)),
                    onPressed: () => setState(() => objects.clear()),
                  ),
                ],
              )
            ],
          ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, ToolType type) {
    bool isActive = selectedTool == type;
    return GestureDetector(
      onTap: () => setState(() => selectedTool = type),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? Colors.cyanAccent.withOpacity(0.2) : Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.cyanAccent : Colors.transparent),
        ),
        child: Icon(icon, color: isActive ? Colors.cyanAccent : Colors.grey, size: 22),
      ),
    );
  }
}

// ==========================================
// 4. THE PHYSICS DRAWING ENGINE
// ==========================================

// Base class for anything drawn
abstract class SketchObject {}

class Point {
  final Offset pos;
  final DateTime time;
  Point(this.pos, this.time);
}

class StrokeObject extends SketchObject {
  final List<Point> points;
  final Color color;
  final double baseWidth;
  final bool isEraser;
  StrokeObject(this.points, this.color, this.baseWidth, this.isEraser);
}

class ShapeObject extends SketchObject {
  final ToolType type;
  final Offset startPoint;
  Offset endPoint;
  final Color color;
  final double width;
  ShapeObject(this.type, this.startPoint, this.endPoint, this.color, this.width);
}

class MasterPainter extends CustomPainter {
  final List<SketchObject> savedObjects;
  final SketchObject? currentObject;

  MasterPainter(this.savedObjects, this.currentObject);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all saved objects
    for (var obj in savedObjects) _drawObject(canvas, obj);
    // Draw current object being dragged
    if (currentObject != null) _drawObject(canvas, currentObject!);
  }

  void _drawObject(Canvas canvas, SketchObject obj) {
    if (obj is StrokeObject) {
      _drawStroke(canvas, obj);
    } else if (obj is ShapeObject) {
      _drawShape(canvas, obj);
    }
  }

  void _drawStroke(Canvas canvas, StrokeObject stroke) {
    Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (stroke.points.length < 2) return;

    for (int i = 0; i < stroke.points.length - 1; i++) {
      Point p1 = stroke.points[i];
      Point p2 = stroke.points[i+1];
      
      double width = stroke.baseWidth;
      
      // FAKE SENSITIVITY ALGORITHM
      // Calculate speed: Distance / Time
      if (!stroke.isEraser) {
        double dist = (p1.pos - p2.pos).distance;
        int time = p2.time.difference(p1.time).inMilliseconds + 1;
        double velocity = dist / time;
        // Inverse: High velocity = Low width
        double factor = (1.5 - (velocity * 0.2)).clamp(0.2, 1.5);
        width = stroke.baseWidth * factor;
      }

      paint.color = stroke.color;
      paint.strokeWidth = width;
      canvas.drawLine(p1.pos, p2.pos, paint);
    }
  }

  void _drawShape(Canvas canvas, ShapeObject shape) {
    Paint paint = Paint()
      ..color = shape.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = shape.width;

    Rect rect = Rect.fromPoints(shape.startPoint, shape.endPoint);

    switch (shape.type) {
      case ToolType.rect:
        canvas.drawRect(rect, paint);
        break;
      case ToolType.circle:
        canvas.drawOval(rect, paint);
        break;
      case ToolType.cube:
        _drawIsometricCube(canvas, rect, paint);
        break;
      default: break;
    }
  }

  // 3D MATH LOGIC
  void _drawIsometricCube(Canvas canvas, Rect rect, Paint paint) {
    double w = rect.width;
    double h = rect.height;
    Offset center = rect.center;
    double size = min(w.abs(), h.abs()) / 2;

    // Front Center Vertex
    Offset v1 = center;
    // Top Vertex
    Offset v2 = center + Offset(0, -size);
    // Bottom Vertex
    Offset v3 = center + Offset(0, size);
    // Top Right
    Offset v4 = center + Offset(size * 0.866, -size * 0.5);
    // Bottom Right
    Offset v5 = center + Offset(size * 0.866, size * 0.5);
    // Top Left
    Offset v6 = center + Offset(-size * 0.866, -size * 0.5);
    // Bottom Left
    Offset v7 = center + Offset(-size * 0.866, size * 0.5);

    // Draw Lines
    canvas.drawLine(v1, v2, paint); // Center Vertical
    canvas.drawLine(v1, v4, paint); // Center to Right
    canvas.drawLine(v1, v6, paint); // Center to Left
    
    // Outer Hexagon
    canvas.drawLine(v2, v4, paint);
    canvas.drawLine(v4, v5, paint);
    canvas.drawLine(v5, v3, paint);
    canvas.drawLine(v3, v7, paint);
    canvas.drawLine(v7, v6, paint);
    canvas.drawLine(v6, v2, paint);
  }

  @override
  bool shouldRepaint(old) => true;
}
