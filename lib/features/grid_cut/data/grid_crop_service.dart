import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../settings/domain/app_settings.dart';
import '../domain/grid_cut_models.dart';

class GridCropService {
  const GridCropService();

  Future<List<String>> exportCells({
    required Uint8List bytes,
    required GridLayout layout,
    required Iterable<int> cellIndexes,
    required Directory outputDirectory,
    required String baseName,
    bool numberEnabled = false,
    CutImageNumberPosition numberPosition = CutImageNumberPosition.topLeft,
    double numberBackgroundOpacity =
        AppSettings.defaultCutImageNumberBackgroundOpacity,
    double numberTextScale = AppSettings.defaultCutImageNumberTextScale,
  }) async {
    final transferable = TransferableTypedData.fromList([bytes]);
    final xLines = List<int>.from(layout.xLines);
    final yLines = List<int>.from(layout.yLines);
    final indexes = cellIndexes.toList(growable: false);
    final outputPath = outputDirectory.path;
    final numberPositionIndex = numberPosition.index;
    return Isolate.run(
      () => _exportCellsInWorker(
        transferable: transferable,
        imageWidth: layout.imageWidth,
        imageHeight: layout.imageHeight,
        xLines: xLines,
        yLines: yLines,
        confidence: layout.confidence,
        usedFallback: layout.usedFallback,
        cellIndexes: indexes,
        outputPath: outputPath,
        baseName: baseName,
        numberEnabled: numberEnabled,
        numberPositionIndex: numberPositionIndex,
        numberBackgroundOpacity: numberBackgroundOpacity,
        numberTextScale: numberTextScale,
      ),
    );
  }

  void _drawNumberBadge(
    img.Image image,
    int number,
    CutImageNumberPosition position,
    double backgroundOpacity,
    double textScale,
  ) {
    final shortestSide = math.min(image.width, image.height);
    if (shortestSide < 12) {
      return;
    }

    final fontScale = textScale.clamp(0.7, 1.6).toDouble();
    var font = _fontForBadge(shortestSide, fontScale);
    final fillAlpha = (backgroundOpacity.clamp(0.0, 1.0).toDouble() * 255)
        .round();
    var text = number.toString();
    var textWidth = _textWidth(text, font);
    var textHeight = font.lineHeight == 0 ? font.base : font.lineHeight;
    var radius = math.max(
      (shortestSide * 0.07 * fontScale).round(),
      (math.max(textWidth, textHeight) / 2).ceil() + 3,
    );

    final maxRadius = math.max(5, (shortestSide / 2).floor() - 2);
    radius = radius.clamp(5, maxRadius).toInt();

    final margin = math.max(3, (radius * 0.35).round());
    var centerX = radius + margin;
    var centerY = radius + margin;
    switch (position) {
      case CutImageNumberPosition.topLeft:
        break;
      case CutImageNumberPosition.bottomLeft:
        centerY = image.height - radius - margin;
        break;
      case CutImageNumberPosition.topRight:
        centerX = image.width - radius - margin;
        break;
      case CutImageNumberPosition.bottomRight:
        centerX = image.width - radius - margin;
        centerY = image.height - radius - margin;
        break;
      case CutImageNumberPosition.center:
        centerX = image.width ~/ 2;
        centerY = image.height ~/ 2;
        break;
    }

    centerX = centerX.clamp(radius, image.width - radius).toInt();
    centerY = centerY.clamp(radius, image.height - radius).toInt();

    img.fillCircle(
      image,
      x: centerX,
      y: centerY,
      radius: radius,
      color: img.ColorRgba8(255, 255, 255, fillAlpha),
      antialias: true,
    );
    img.drawCircle(
      image,
      x: centerX,
      y: centerY,
      radius: radius,
      color: img.ColorRgba8(0, 0, 0, 170),
      antialias: true,
    );
    if (radius > 8) {
      img.drawCircle(
        image,
        x: centerX,
        y: centerY,
        radius: radius - 1,
        color: img.ColorRgba8(0, 0, 0, 130),
        antialias: true,
      );
    }
    img.drawString(
      image,
      text,
      font: font,
      x: centerX - (textWidth / 2).round(),
      y: centerY - (textHeight / 2).round(),
      color: img.ColorRgb8(20, 20, 20),
    );
  }

  img.BitmapFont _fontForBadge(int shortestSide, double textScale) {
    final targetHeight = shortestSide * 0.07 * textScale;
    if (targetHeight >= 34) {
      return img.arial48;
    }
    if (targetHeight >= 18) {
      return img.arial24;
    }
    return img.arial14;
  }

  int _textWidth(String text, img.BitmapFont font) {
    var width = 0;
    for (final codeUnit in text.codeUnits) {
      width += font.characters[codeUnit]?.xAdvance ?? font.base ~/ 2;
    }
    return width;
  }
}

Future<List<String>> _exportCellsInWorker({
  required TransferableTypedData transferable,
  required int imageWidth,
  required int imageHeight,
  required List<int> xLines,
  required List<int> yLines,
  required double confidence,
  required bool usedFallback,
  required List<int> cellIndexes,
  required String outputPath,
  required String baseName,
  required bool numberEnabled,
  required int numberPositionIndex,
  required double numberBackgroundOpacity,
  required double numberTextScale,
}) async {
  final bytes = transferable.materialize().asUint8List();
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw const FormatException('无法解析图片');
  }
  final layout = GridLayout(
    imageWidth: imageWidth,
    imageHeight: imageHeight,
    xLines: xLines,
    yLines: yLines,
    confidence: confidence,
    usedFallback: usedFallback,
  );
  final outputDirectory = Directory(outputPath);
  if (!outputDirectory.existsSync()) {
    await outputDirectory.create(recursive: true);
  }
  final service = const GridCropService();
  final numberPosition = CutImageNumberPosition.values[numberPositionIndex];
  final exported = <String>[];
  for (final cellIndex in cellIndexes) {
    final cell = layout.cellAt(cellIndex);
    final gridNumber = cellIndex + 1;
    final cropped = img.copyCrop(
      image,
      x: cell.x,
      y: cell.y,
      width: cell.width,
      height: cell.height,
    );
    if (numberEnabled) {
      service._drawNumberBadge(
        cropped,
        gridNumber,
        numberPosition,
        numberBackgroundOpacity,
        numberTextScale,
      );
    }
    final file = File(p.join(outputPath, '$baseName$gridNumber.png'));
    await file.writeAsBytes(img.encodePng(cropped));
    exported.add(file.path);
  }
  return exported;
}
