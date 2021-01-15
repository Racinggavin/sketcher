import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketcher/sketcher.dart';
import 'package:sketcher/src/models/stroke.dart';
import 'package:sketcher/src/tools/eraser_controller.dart';
import 'package:sketcher/src/tools/pencil_controller.dart';
import 'package:sketcher/src/ui/operations/stroke_operation.dart';

void main() {
  group('PencilController', () {
    test('should not provide a tool painter by default', () {
      final sketchController = SketchController();
      sketchController.setActiveTool(SketchTool.Pencil);
      final pencil = PencilController(sketchController, () {});
      expect(pencil.toolPainter, isNull);
    });

    test('should provide a tool painter after activation', () {
      final sketchController = SketchController();
      sketchController.setActiveTool(SketchTool.Pencil);
      final pencil = PencilController(sketchController, () {});
      pencil.panStart(const PointerDownEvent());
      expect(pencil.toolPainter, isNotNull);
    });

    test('should add a stroke', () {
      final sketchController = SketchController();
      sketchController.setActiveTool(SketchTool.Pencil);
      final pencil = PencilController(sketchController, () {});
      pencil.panStart(const PointerDownEvent(position: Offset(0, 0)));
      pencil.panUpdate(const PointerMoveEvent(position: Offset(10, 0)));
      pencil.panEnd(const PointerUpEvent());
      expect(sketchController.layers, hasLength(1));
      expect(sketchController.layers.first.painter.strokes, hasLength(1));
    });
  });

  group('EraserController', () {
    test('should not provide a tool painter by default', () {
      final sketchController = SketchController();
      sketchController.setActiveTool(SketchTool.Eraser);
      final eraser = EraserController(sketchController, () {});
      expect(eraser.toolPainter, isNull);
    });

    test('should not provide a tool painter after activation', () {
      final sketchController = SketchController();
      sketchController.setActiveTool(SketchTool.Eraser);
      final eraser = EraserController(sketchController, () {});
      eraser.panStart(const PointerDownEvent());
      expect(eraser.toolPainter, isNull);
    });

    test('should remove a stroke', () {
      final sketchController = SketchController();
      const stroke = Stroke([Offset(0, 0), Offset(10, 10)], Colors.red, 1);
      sketchController.commitOperation(
          StrokeOperation(stroke, sketchController.nextLayerId));
      sketchController.setActiveTool(SketchTool.Eraser);
      final eraser = EraserController(sketchController, () {});
      eraser.panStart(const PointerDownEvent(position: Offset(0, 0)));
      eraser.panUpdate(const PointerMoveEvent(position: Offset(10, 0)));
      eraser.panEnd(const PointerUpEvent());
      expect(sketchController.layers, hasLength(1));
      expect(sketchController.layers.first.painter.strokes, isEmpty);
    });
  });

  group('StrokeOperation', () {
    test('should add a stroke', () {
      final sketchController = SketchController();
      const stroke = Stroke([Offset(0, 0), Offset(10, 0)], Colors.red, 1.0);
      final operation = StrokeOperation(stroke, sketchController.nextLayerId);
      sketchController.commitOperation(operation);
      expect(sketchController.layers, hasLength(1));
      expect(sketchController.layers.first.painter.strokes, hasLength(1));
    });

    test('should undo the add operation', () {
      final sketchController = SketchController();
      const stroke = Stroke([Offset(0, 0), Offset(10, 0)], Colors.red, 1.0);
      final operation = StrokeOperation(stroke, sketchController.nextLayerId);
      sketchController.commitOperation(operation);
      sketchController.undo();
      expect(sketchController.layers, isEmpty);
    });
  });
}
