import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:storyboard_grid_app/features/grid_cut/data/grid_crop_service.dart';
import 'package:storyboard_grid_app/features/grid_cut/data/grid_detection_service.dart';
import 'package:storyboard_grid_app/features/grid_cut/domain/grid_cut_models.dart';
import 'package:storyboard_grid_app/features/settings/domain/app_settings.dart';
import 'package:test/test.dart';

void main() {
  test('识别简单 3x3 宫格线', () {
    final image = img.Image(width: 90, height: 90);
    img.fill(image, color: img.ColorRgb8(230, 230, 230));
    for (final line in [30, 60]) {
      img.fillRect(
        image,
        x1: line - 1,
        y1: 0,
        x2: line + 1,
        y2: 89,
        color: img.ColorRgb8(255, 255, 255),
      );
      img.fillRect(
        image,
        x1: 0,
        y1: line - 1,
        x2: 89,
        y2: line + 1,
        color: img.ColorRgb8(255, 255, 255),
      );
    }

    final layout = const GridDetectionService().detect(
      Uint8List.fromList(img.encodePng(image)),
    );

    expect(layout.rows, 3);
    expect(layout.columns, 3);
    expect(layout.usedFallback, isFalse);
  });

  test('异步宫格识别保持主事件循环响应且结果一致', () async {
    final image = img.Image(width: 1200, height: 1200);
    img.fill(image, color: img.ColorRgb8(210, 220, 230));
    final bytes = Uint8List.fromList(img.encodePng(image));
    final service = const GridDetectionService();
    final expected = service.detect(bytes);
    var heartbeatCount = 0;
    final heartbeat = Timer.periodic(
      const Duration(milliseconds: 1),
      (_) => heartbeatCount++,
    );

    final actual = await service.detectAsync(bytes);
    heartbeat.cancel();

    expect(heartbeatCount, greaterThan(0));
    expect(actual.imageWidth, expected.imageWidth);
    expect(actual.imageHeight, expected.imageHeight);
    expect(actual.xLines, expected.xLines);
    expect(actual.yLines, expected.yLines);
    expect(actual.usedFallback, expected.usedFallback);
  });

  test('自动识别支持只有横向裁切线的竖屏多宫格', () {
    final image = img.Image(width: 90, height: 300);
    img.fill(image, color: img.ColorRgb8(150, 170, 190));
    for (final y in [100, 200]) {
      img.fillRect(
        image,
        x1: 0,
        y1: y - 1,
        x2: 89,
        y2: y + 1,
        color: img.ColorRgb8(255, 255, 255),
      );
    }

    final layout = const GridDetectionService().detect(
      Uint8List.fromList(img.encodePng(image)),
    );

    expect(layout.rows, 3);
    expect(layout.columns, 1);
    expect(layout.xLines, [0, 90]);
    expect(layout.yLines, [0, 100, 200, 300]);
    expect(layout.usedFallback, isFalse);
  });

  test('未识别到分隔线时保持单格而不是默认9宫格', () {
    final image = img.Image(width: 90, height: 160);
    img.fill(image, color: img.ColorRgb8(150, 170, 190));

    final layout = const GridDetectionService().detect(
      Uint8List.fromList(img.encodePng(image)),
    );

    expect(layout.rows, 1);
    expect(layout.columns, 1);
    expect(layout.cellCount, 1);
    expect(layout.usedFallback, isTrue);
  });

  test('异步宫格识别会把无效图片异常传回调用方', () async {
    await expectLater(
      const GridDetectionService().detectAsync(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<FormatException>()),
    );
  });

  test('裁切导出使用原文件名加数字序号', () async {
    final root = await Directory.systemTemp.createTemp('storyboard_crop_');
    addTearDown(() => root.delete(recursive: true));

    final image = img.Image(width: 80, height: 40);
    img.fill(image, color: img.ColorRgb8(120, 160, 200));
    final layout = const GridDetectionService().evenGrid(
      imageWidth: 80,
      imageHeight: 40,
      rows: 1,
      columns: 2,
    );

    final paths = await const GridCropService().exportCells(
      bytes: Uint8List.fromList(img.encodePng(image)),
      layout: layout,
      cellIndexes: [0, 1],
      outputDirectory: root,
      baseName: 'demo',
    );

    expect(paths.length, 2);
    expect(
      File('${root.path}${Platform.pathSeparator}demo1.png').existsSync(),
      isTrue,
    );
    expect(
      File('${root.path}${Platform.pathSeparator}demo2.png').existsSync(),
      isTrue,
    );
  });

  test('裁切导出选中部分格子时保留原宫格绝对编号', () async {
    final root = await Directory.systemTemp.createTemp('storyboard_crop_');
    addTearDown(() => root.delete(recursive: true));

    final image = img.Image(width: 90, height: 60);
    img.fill(image, color: img.ColorRgb8(120, 160, 200));
    final layout = const GridDetectionService().evenGrid(
      imageWidth: 90,
      imageHeight: 60,
      rows: 2,
      columns: 3,
    );

    final paths = await const GridCropService().exportCells(
      bytes: Uint8List.fromList(img.encodePng(image)),
      layout: layout,
      cellIndexes: [1, 4],
      outputDirectory: root,
      baseName: 'demo',
      numberEnabled: true,
    );

    expect(paths.map((path) => File(path).uri.pathSegments.last), [
      'demo2.png',
      'demo5.png',
    ]);
    expect(
      File('${root.path}${Platform.pathSeparator}demo1.png').existsSync(),
      isFalse,
    );
  });

  test('裁切导出默认不写入图片编号', () async {
    final root = await Directory.systemTemp.createTemp('storyboard_crop_');
    addTearDown(() => root.delete(recursive: true));

    final image = img.Image(width: 80, height: 40);
    img.fill(image, color: img.ColorRgb8(120, 160, 200));
    final layout = const GridDetectionService().evenGrid(
      imageWidth: 80,
      imageHeight: 40,
      rows: 1,
      columns: 2,
    );

    final paths = await const GridCropService().exportCells(
      bytes: Uint8List.fromList(img.encodePng(image)),
      layout: layout,
      cellIndexes: [0],
      outputDirectory: root,
      baseName: 'demo',
    );

    final exported = img.decodePng(await File(paths.first).readAsBytes())!;
    expect(_hasChangedPixel(exported), isFalse);
  });

  test('裁切导出开启编号后按指定位置绘制徽章', () async {
    final root = await Directory.systemTemp.createTemp('storyboard_crop_');
    addTearDown(() => root.delete(recursive: true));

    final image = img.Image(width: 200, height: 200);
    img.fill(image, color: img.ColorRgb8(120, 160, 200));
    const layout = GridLayout(
      imageWidth: 200,
      imageHeight: 200,
      xLines: [0, 200],
      yLines: [0, 200],
      confidence: 1,
      usedFallback: false,
    );

    for (final probe in _numberPositionProbes) {
      final outputDirectory = Directory(
        '${root.path}${Platform.pathSeparator}${probe.position.name}',
      );
      final paths = await const GridCropService().exportCells(
        bytes: Uint8List.fromList(img.encodePng(image)),
        layout: layout,
        cellIndexes: [0],
        outputDirectory: outputDirectory,
        baseName: 'demo',
        numberEnabled: true,
        numberPosition: probe.position,
      );

      final exported = img.decodePng(await File(paths.first).readAsBytes())!;
      expect(
        _hasChangedPixel(
          exported,
          x1: probe.x1,
          y1: probe.y1,
          x2: probe.x2,
          y2: probe.y2,
        ),
        isTrue,
        reason: '${probe.position.label} 应出现编号像素',
      );
    }
  });

  test('裁切导出图片编号徽章不会覆盖旧版大尺寸外圈区域', () async {
    final root = await Directory.systemTemp.createTemp('storyboard_crop_');
    addTearDown(() => root.delete(recursive: true));

    final image = img.Image(width: 200, height: 200);
    img.fill(image, color: img.ColorRgb8(_baseR, _baseG, _baseB));
    const layout = GridLayout(
      imageWidth: 200,
      imageHeight: 200,
      xLines: [0, 200],
      yLines: [0, 200],
      confidence: 1,
      usedFallback: false,
    );

    final paths = await const GridCropService().exportCells(
      bytes: Uint8List.fromList(img.encodePng(image)),
      layout: layout,
      cellIndexes: [0],
      outputDirectory: root,
      baseName: 'demo',
      numberEnabled: true,
      numberPosition: CutImageNumberPosition.topLeft,
    );

    final exported = img.decodePng(await File(paths.first).readAsBytes())!;
    expect(_hasChangedPixel(exported, x1: 45, y1: 12, x2: 62, y2: 30), isFalse);
  });

  test('手动插入裁切线会排序、去重并限制边界', () {
    const layout = GridLayout(
      imageWidth: 100,
      imageHeight: 80,
      xLines: [0, 50, 100],
      yLines: [0, 40, 80],
      confidence: 0.35,
      usedFallback: true,
    );

    final inserted = layout.insertVerticalLine(25);
    expect(inserted.xLines, [0, 25, 50, 100]);
    expect(inserted.columns, 3);

    final duplicate = inserted.insertVerticalLine(25);
    expect(duplicate.xLines, inserted.xLines);

    final clamped = layout.insertVerticalLine(2);
    expect(clamped.xLines, [0, GridLayout.minLineGap, 50, 100]);

    final horizontal = layout.insertHorizontalLine(60);
    expect(horizontal.yLines, [0, 40, 60, 80]);

    const tight = GridLayout(
      imageWidth: 100,
      imageHeight: 80,
      xLines: [0, 12, 100],
      yLines: [0, 80],
      confidence: 0.35,
      usedFallback: true,
    );
    expect(tight.insertVerticalLine(6).xLines, [0, 12, 100]);
  });

  test('拖动裁切线可跨越相邻线并保持最小间距', () {
    const layout = GridLayout(
      imageWidth: 100,
      imageHeight: 80,
      xLines: [0, 30, 60, 100],
      yLines: [0, 20, 40, 80],
      confidence: 0.35,
      usedFallback: true,
    );

    final movedRight = layout.moveVerticalLine(1, 76);
    expect(movedRight.xLines, [0, 60, 76, 100]);

    final movedRightWithIndex = layout.moveVerticalLineWithIndex(1, 76);
    expect(movedRightWithIndex.layout.xLines, [0, 60, 76, 100]);
    expect(movedRightWithIndex.lineIndex, 2);

    final movedLeft = layout.moveHorizontalLine(2, 10);
    expect(movedLeft.yLines, [0, 10, 20, 80]);

    final clampedNearNeighbor = layout.moveVerticalLine(1, 58);
    expect(clampedNearNeighbor.xLines, [0, 52, 60, 100]);
  });

  test('手动移除裁切线时保留边界并支持单轴布局', () {
    const layout = GridLayout(
      imageWidth: 100,
      imageHeight: 120,
      xLines: [0, 50, 100],
      yLines: [0, 40, 80, 120],
      confidence: 0.8,
      usedFallback: false,
    );

    final withoutVertical = layout.removeVerticalLine(1);
    expect(withoutVertical.xLines, [0, 100]);
    expect(withoutVertical.columns, 1);
    expect(withoutVertical.rows, 3);

    final withoutHorizontal = withoutVertical.removeHorizontalLine(2);
    expect(withoutHorizontal.yLines, [0, 40, 120]);
    expect(withoutHorizontal.rows, 2);
    expect(withoutHorizontal.removeHorizontalLine(0), same(withoutHorizontal));
    expect(
      withoutHorizontal.removeHorizontalLine(
        withoutHorizontal.yLines.length - 1,
      ),
      same(withoutHorizontal),
    );
  });
}

const _baseR = 120;
const _baseG = 160;
const _baseB = 200;

const _numberPositionProbes = [
  _NumberPositionProbe(CutImageNumberPosition.topLeft, 25, 25, 60, 60),
  _NumberPositionProbe(CutImageNumberPosition.bottomLeft, 25, 140, 60, 175),
  _NumberPositionProbe(CutImageNumberPosition.topRight, 140, 25, 175, 60),
  _NumberPositionProbe(CutImageNumberPosition.bottomRight, 140, 140, 175, 175),
  _NumberPositionProbe(CutImageNumberPosition.center, 82, 82, 118, 118),
];

class _NumberPositionProbe {
  const _NumberPositionProbe(this.position, this.x1, this.y1, this.x2, this.y2);

  final CutImageNumberPosition position;
  final int x1;
  final int y1;
  final int x2;
  final int y2;
}

bool _hasChangedPixel(
  img.Image image, {
  int x1 = 0,
  int y1 = 0,
  int? x2,
  int? y2,
}) {
  final maxX = x2 ?? image.width - 1;
  final maxY = y2 ?? image.height - 1;
  for (var y = y1; y <= maxY; y++) {
    for (var x = x1; x <= maxX; x++) {
      final pixel = image.getPixel(x, y);
      if ((pixel.r - _baseR).abs() > 2 ||
          (pixel.g - _baseG).abs() > 2 ||
          (pixel.b - _baseB).abs() > 2) {
        return true;
      }
    }
  }
  return false;
}
