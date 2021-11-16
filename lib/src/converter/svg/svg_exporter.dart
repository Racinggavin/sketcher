import 'dart:ui';

import 'package:sketcher/src/converter/exporter.dart';
import 'package:sketcher/src/models/curve.dart';
import 'package:sketcher/src/models/path_curve.dart';
import 'package:sketcher/src/models/stroke.dart';
import 'package:sketcher/src/ui/sketch_controller.dart';
import 'package:xml/xml.dart';

/// A utility class for decoding a [SketchController] to SVG data
class SvgExporter implements Exporter {
  @override
  String export(
    SketchController controller, {
    bool exportBackgroundColor = false,
    int precision = 2,
    Size? bound
  }) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element(
      "svg",
      nest: () {
        if (exportBackgroundColor) {
          builder.attribute(
            "viewport-fill",
            _flutterColorToSvgColor(controller.backgroundColor.value),
          );
        }
        Offset? offset = _exportViewBox(builder, controller, bound);
        if(offset != null) {
          for (final layer in controller.layers) {
            for (final stroke in layer.painter.curves) {
              _toPath(builder, stroke, precision, offset);
            }
          }
        }
      },
    );
    return builder.buildDocument().outerXml;
  }

  Offset? _exportViewBox(XmlBuilder builder, SketchController controller, Size? bound) {
    try {
      final overallRect = controller.layers.map((layer) {
        return layer.painter.curves.map((curve) {
          return curve.points
              .map((offset) => Rect.fromPoints(offset, offset))
              .reduce(_expandToInclude);
        }).reduce(_expandToInclude);
      }).reduce(_expandToInclude);
      final width = overallRect.width.ceil() + 40;
      final height = overallRect.height.ceil() + 40;
      builder.attribute("width", bound?.width ?? width);
      builder.attribute("height", bound?.height ?? height);
      builder.attribute("viewBox", "0 0 ${bound?.width ?? width} ${bound?.height ?? height}");
      builder.attribute("fill", "none");
      builder.attribute("xmlns", "http://www.w3.org/2000/svg");
      return bound == null ? Offset(- (overallRect.left - 20), -(overallRect.top - 20)) : Offset.zero;
    } on Object {
      // doesn't have enough points to calculate a view box
      return null;
    }
  }

  Rect _expandToInclude(Rect rect1, Rect rect2) {
    return rect1.expandToInclude(rect2);
  }

  void _toPath(XmlBuilder builder, Curve curve, int precision, Offset offset) {
    if (curve is PathCurve) {
      builder.element(
        "path",
        attributes: {
          for (var attr in curve.originPath.attributes)
            attr.name.local: attr.value,
        },
      );
    } else if (curve is Stroke) {
      final d = StringBuffer();
      d.write(
        "M${(curve.points.first.dx + offset.dx).toStringAsFixed(precision)} ${(curve.points.first.dy + offset.dy).toStringAsFixed(precision)}",
      );
      for (final point in curve.points.skip(1)) {
        d.write(
          " L${(point.dx + offset.dx).toStringAsFixed(precision)} ${(point.dy + offset.dy).toStringAsFixed(precision)}",
        );
      }
      builder.element(
        "path",
        attributes: {
          "id": "sketcher-v1",
          "d": d.toString(),
          "stroke": _flutterColorToSvgColor(curve.color.value),
          "stroke-opacity": curve.color.opacity.toString(),
          "stroke-width": curve.weight.toStringAsFixed(0),
          "stroke-linecap": "round",
          "fill": "none"
        },
      );
    } else {
      throw ArgumentError.value(curve, "curve", "Unknown curve type");
    }
  }

  static String _flutterColorToSvgColor(int color) {
    final fullColor = color.toRadixString(16).toUpperCase().padLeft(8, "0");
    final onlyColor = fullColor.substring(fullColor.length - 6);
    return "#$onlyColor";
  }
}
