import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../storyboard/domain/storyboard_models.dart';

String shootingScriptExportFileName({
  required String boardName,
  DateTime? date,
}) {
  final normalizedBoardName = boardName
      .trim()
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[. ]+$'), '');
  final safeBoardName = normalizedBoardName.isEmpty
      ? '画板'
      : normalizedBoardName;
  final dateText = DateFormat('yyyyMMdd').format(date ?? DateTime.now());
  return '$safeBoardName-拍摄脚本-$dateText.xlsx';
}

class ShootingScriptExportService {
  const ShootingScriptExportService();

  static const _templateAsset = 'docs/拍摄脚本模版.xlsx';
  static const _firstDataRow = 3;
  static const _templateLastDataRow = 15;
  static const _imageWidth = 400;
  static const _imageHeight = 238;

  Future<File> export({
    required List<StoryboardBoard> boards,
    required Map<String, VisionAnalysisBatchRecord?> analysisBatches,
    required String outputPath,
  }) async {
    if (boards.isEmpty) {
      throw const FormatException('请至少选择一个画板');
    }

    final templateData = await rootBundle.load(_templateAsset);
    final entries = _readArchive(
      templateData.buffer.asUint8List(
        templateData.offsetInBytes,
        templateData.lengthInBytes,
      ),
    );
    final templateSheet = _textEntry(entries, 'xl/worksheets/sheet1.xml');
    final workbookXml = _textEntry(entries, 'xl/workbook.xml');
    final workbookRelsXml = _textEntry(entries, 'xl/_rels/workbook.xml.rels');
    final contentTypesXml = _textEntry(entries, '[Content_Types].xml');

    final sheets = <_ShootingScriptSheet>[];
    for (final board in boards) {
      sheets.add(
        await _ShootingScriptSheet.fromBoard(
          board: board,
          analysisBatch: analysisBatches[board.id],
        ),
      );
    }

    final usedSheetNames = <String>{};
    for (final sheet in sheets) {
      sheet.name = _uniqueSheetName(sheet.board.name, usedSheetNames);
    }

    var nextImageNumber = 1;
    for (var index = 0; index < sheets.length; index++) {
      final sheetNumber = index + 1;
      final sheet = sheets[index];
      final dataEndRow = math.max(
        _templateLastDataRow,
        _firstDataRow + sheet.shots.length - 1,
      );
      final imageRefs = <_EmbeddedImage>[];
      for (var shotIndex = 0; shotIndex < sheet.shots.length; shotIndex++) {
        final shot = sheet.shots[shotIndex];
        final imageName = 'image$nextImageNumber.png';
        nextImageNumber++;
        entries['xl/media/$imageName'] = shot.pngBytes;
        imageRefs.add(
          _EmbeddedImage(
            relationshipId: 'rId${shotIndex + 1}',
            imageName: imageName,
            row: _firstDataRow + shotIndex,
            width: shot.displayWidth,
            height: shot.displayHeight,
          ),
        );
      }

      entries['xl/worksheets/sheet$sheetNumber.xml'] = utf8.encode(
        _buildSheetXml(
          templateSheet,
          sheet.shots,
          dataEndRow,
          hasImages: imageRefs.isNotEmpty,
        ),
      );
      if (imageRefs.isNotEmpty) {
        entries['xl/worksheets/_rels/sheet$sheetNumber.xml.rels'] = utf8.encode(
          _worksheetRelationshipsXml(sheetNumber),
        );
        entries['xl/drawings/drawing$sheetNumber.xml'] = utf8.encode(
          _drawingXml(imageRefs),
        );
        entries['xl/drawings/_rels/drawing$sheetNumber.xml.rels'] = utf8.encode(
          _drawingRelationshipsXml(imageRefs),
        );
      }
    }

    entries['xl/workbook.xml'] = utf8.encode(_workbookXml(workbookXml, sheets));
    entries['xl/_rels/workbook.xml.rels'] = utf8.encode(
      _workbookRelationshipsXml(workbookRelsXml, sheets.length),
    );
    entries['[Content_Types].xml'] = utf8.encode(
      _contentTypesXml(contentTypesXml, sheets),
    );

    final output = Archive();
    for (final entry in entries.entries) {
      output.addFile(ArchiveFile.bytes(entry.key, entry.value));
    }
    final file = File(_ensureXlsxExtension(outputPath));
    if (!file.parent.existsSync()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsBytes(ZipEncoder().encodeBytes(output), flush: true);
    return file;
  }

  Map<String, Uint8List> _readArchive(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final result = <String, Uint8List>{};
    for (final file in archive) {
      if (!file.isFile) {
        continue;
      }
      final content = file.readBytes();
      if (content == null) {
        throw FormatException('拍摄脚本模板无法读取：${file.name}');
      }
      result[file.name] = Uint8List.fromList(content);
    }
    return result;
  }

  String _textEntry(Map<String, Uint8List> entries, String path) {
    final value = entries[path];
    if (value == null) {
      throw FormatException('拍摄脚本模板缺少文件：$path');
    }
    return utf8.decode(value);
  }

  String _buildSheetXml(
    String template,
    List<_ShootingScriptShot> shots,
    int dataEndRow, {
    required bool hasImages,
  }) {
    final dataMatch = RegExp(
      r'<sheetData>.*?</sheetData>',
      dotAll: true,
    ).firstMatch(template);
    if (dataMatch == null) {
      throw const FormatException('拍摄脚本模板缺少数据行');
    }
    final header = RegExp(
      r'<row r="[12]".*?</row>',
      dotAll: true,
    ).allMatches(dataMatch.group(0)!).map((match) => match.group(0)!).join();
    final sourceRows = <int, String>{
      for (var row = _firstDataRow; row <= _templateLastDataRow; row++)
        row: _extractRow(dataMatch.group(0)!, row),
    };
    final rows = StringBuffer(header);
    for (var row = _firstDataRow; row <= dataEndRow; row++) {
      final sourceRow = math.min(row, _templateLastDataRow);
      final shotIndex = row - _firstDataRow;
      final shot = shotIndex < shots.length ? shots[shotIndex] : null;
      rows.write(_filledRow(sourceRows[sourceRow]!, sourceRow, row, shot));
    }

    var result = template.replaceRange(
      dataMatch.start,
      dataMatch.end,
      '<sheetData>${rows.toString()}</sheetData>',
    );
    result = result.replaceFirst(
      RegExp(r'<dimension ref="A1:Y\d+"/>'),
      '<dimension ref="A1:Y$dataEndRow"/>',
    );
    result = result.replaceAll('D3:D15', 'D3:D$dataEndRow');
    result = result.replaceAll('E3:E15', 'E3:E$dataEndRow');
    if (hasImages && !result.contains('<drawing ')) {
      final pageMargins = RegExp(r'<pageMargins\b[^>]*/>').firstMatch(result);
      if (pageMargins == null) {
        throw const FormatException('拍摄脚本模板缺少页边距设置');
      }
      result = result.replaceRange(
        pageMargins.start,
        pageMargins.end,
        '${pageMargins.group(0)}<drawing r:id="rId1"/>',
      );
    }
    return result;
  }

  String _extractRow(String sheetData, int row) {
    final match = RegExp(
      '<row r="$row".*?</row>',
      dotAll: true,
    ).firstMatch(sheetData);
    if (match == null) {
      throw FormatException('拍摄脚本模板缺少第 $row 行');
    }
    return match.group(0)!;
  }

  String _filledRow(
    String source,
    int sourceRow,
    int row,
    _ShootingScriptShot? shot,
  ) {
    var result = source.replaceFirst('r="$sourceRow"', 'r="$row"');
    result = result.replaceAllMapped(
      RegExp('r="([A-Z]+)$sourceRow"'),
      (match) => 'r="${match.group(1)}$row"',
    );
    result = _replaceCell(
      result,
      'A',
      row,
      shot?.number.toString(),
      numeric: true,
    );
    result = _replaceCell(result, 'C', row, shot?.content);
    result = _replaceCell(result, 'D', row, shot?.shotSize);
    return _replaceCell(result, 'E', row, shot?.cameraMovement);
  }

  String _replaceCell(
    String rowXml,
    String column,
    int row,
    String? value, {
    bool numeric = false,
  }) {
    final expression = RegExp(
      '<c r="$column$row"([^>]*)>(?:.*?)</c>|<c r="$column$row"([^>]*)/>',
      dotAll: true,
    );
    final match = expression.firstMatch(rowXml);
    if (match == null) {
      throw FormatException('拍摄脚本模板缺少 $column$row 单元格');
    }
    final attributes = match.group(1) ?? match.group(2) ?? '';
    final trimmed = value?.trim() ?? '';
    final replacement = trimmed.isEmpty
        ? '<c r="$column$row"$attributes/>'
        : numeric
        ? '<c r="$column$row"$attributes><v>$trimmed</v></c>'
        : '<c r="$column$row"$attributes t="inlineStr"><is><t>${_xmlEscape(trimmed)}</t></is></c>';
    return rowXml.replaceRange(match.start, match.end, replacement);
  }

  String _workbookXml(String template, List<_ShootingScriptSheet> sheets) {
    final sheetTags = StringBuffer();
    for (var index = 0; index < sheets.length; index++) {
      final sheetId = index + 2;
      final relationshipId = index == 0 ? 'rId1' : 'rId${index + 4}';
      sheetTags.write(
        '<sheet name="${_xmlEscape(sheets[index].name)}" sheetId="$sheetId" r:id="$relationshipId"/>',
      );
    }
    return template.replaceFirst(
      RegExp(r'<sheets>.*?</sheets>', dotAll: true),
      '<sheets>$sheetTags</sheets>',
    );
  }

  String _workbookRelationshipsXml(String template, int sheetCount) {
    final extras = StringBuffer();
    for (var sheetNumber = 2; sheetNumber <= sheetCount; sheetNumber++) {
      extras.write(
        '<Relationship Id="rId${sheetNumber + 3}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$sheetNumber.xml"/>',
      );
    }
    return template.replaceFirst('</Relationships>', '$extras</Relationships>');
  }

  String _contentTypesXml(String template, List<_ShootingScriptSheet> sheets) {
    final extras = StringBuffer();
    if (!template.contains('Extension="png"')) {
      extras.write('<Default Extension="png" ContentType="image/png"/>');
    }
    for (var sheetNumber = 2; sheetNumber <= sheets.length; sheetNumber++) {
      extras.write(
        '<Override PartName="/xl/worksheets/sheet$sheetNumber.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
      );
    }
    for (var sheetNumber = 1; sheetNumber <= sheets.length; sheetNumber++) {
      if (sheets[sheetNumber - 1].shots.isNotEmpty) {
        extras.write(
          '<Override PartName="/xl/drawings/drawing$sheetNumber.xml" ContentType="application/vnd.openxmlformats-officedocument.drawing+xml"/>',
        );
      }
    }
    return template.replaceFirst('</Types>', '$extras</Types>');
  }

  String _worksheetRelationshipsXml(int sheetNumber) {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing" Target="../drawings/drawing$sheetNumber.xml"/>'
        '</Relationships>';
  }

  String _drawingXml(List<_EmbeddedImage> images) {
    final anchors = StringBuffer();
    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      anchors.write('''
<xdr:oneCellAnchor>
<xdr:from><xdr:col>1</xdr:col><xdr:colOff>47625</xdr:colOff><xdr:row>${image.row - 1}</xdr:row><xdr:rowOff>47625</xdr:rowOff></xdr:from>
<xdr:ext cx="${image.width * 9525}" cy="${image.height * 9525}"/>
<xdr:pic><xdr:nvPicPr><xdr:cNvPr id="${index + 1}" name="画面${index + 1}"/><xdr:cNvPicPr/></xdr:nvPicPr><xdr:blipFill><a:blip r:embed="${image.relationshipId}"/><a:stretch><a:fillRect/></a:stretch></xdr:blipFill><xdr:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="${image.width * 9525}" cy="${image.height * 9525}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></xdr:spPr></xdr:pic><xdr:clientData/>
</xdr:oneCellAnchor>''');
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">$anchors</xdr:wsDr>';
  }

  String _drawingRelationshipsXml(List<_EmbeddedImage> images) {
    final relations = images
        .map(
          (image) =>
              '<Relationship Id="${image.relationshipId}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/${image.imageName}"/>',
        )
        .join();
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">$relations</Relationships>';
  }

  String _uniqueSheetName(String value, Set<String> usedNames) {
    final base = value.trim().replaceAll(RegExp(r'[\\/:?*\[\]]'), '_');
    final fallback = base.isEmpty ? '画板' : base;
    var candidate = fallback.substring(0, math.min(31, fallback.length));
    var suffix = 2;
    while (!usedNames.add(candidate.toLowerCase())) {
      final marker = '-$suffix';
      candidate =
          '${fallback.substring(0, math.min(31 - marker.length, fallback.length))}$marker';
      suffix++;
    }
    return candidate;
  }

  String _ensureXlsxExtension(String path) {
    return p.extension(path).toLowerCase() == '.xlsx' ? path : '$path.xlsx';
  }

  String _xmlEscape(String value) {
    final sanitized = String.fromCharCodes(
      value.runes.where(
        (character) =>
            character == 0x9 ||
            character == 0xA ||
            character == 0xD ||
            (character >= 0x20 && character <= 0xD7FF) ||
            (character >= 0xE000 && character <= 0xFFFD) ||
            (character >= 0x10000 && character <= 0x10FFFF),
      ),
    );
    return sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _ShootingScriptSheet {
  _ShootingScriptSheet({required this.board, required this.shots});

  final StoryboardBoard board;
  final List<_ShootingScriptShot> shots;
  late String name;

  static Future<_ShootingScriptSheet> fromBoard({
    required StoryboardBoard board,
    required VisionAnalysisBatchRecord? analysisBatch,
  }) async {
    final analyses = {
      for (final item
          in analysisBatch?.items ?? const <VisionAnalysisItemRecord>[])
        item.cutResultId: item,
    };
    final items = board.items.toList()
      ..sort((left, right) => left.slotIndex.compareTo(right.slotIndex));
    final shots = <_ShootingScriptShot>[];
    for (final item in items) {
      if (item.slotIndex < 0 || item.slotIndex >= board.slotCount) {
        continue;
      }
      final analysis = analyses[item.asset.id];
      shots.add(
        await _ShootingScriptShot.fromItem(
          item: item,
          number: shots.length + 1,
          analysis: analysis,
        ),
      );
    }
    return _ShootingScriptSheet(board: board, shots: shots);
  }
}

class _ShootingScriptShot {
  const _ShootingScriptShot({
    required this.number,
    required this.content,
    required this.shotSize,
    required this.cameraMovement,
    required this.pngBytes,
    required this.displayWidth,
    required this.displayHeight,
  });

  final int number;
  final String content;
  final String shotSize;
  final String cameraMovement;
  final Uint8List pngBytes;
  final int displayWidth;
  final int displayHeight;

  static Future<_ShootingScriptShot> fromItem({
    required StoryboardItem item,
    required int number,
    required VisionAnalysisItemRecord? analysis,
  }) async {
    final source = File(item.asset.path);
    if (!source.existsSync()) {
      throw FormatException('镜号 $number 的画面文件不存在：${item.asset.path}');
    }
    final transferable = TransferableTypedData.fromList([
      await source.readAsBytes(),
    ]);
    late final Map<String, Object> prepared;
    try {
      prepared = await Isolate.run(
        () => _prepareShootingScriptImage(
          transferable,
          flipHorizontal: item.flipHorizontal,
          flipVertical: item.flipVertical,
        ),
      );
    } on FormatException {
      throw FormatException('镜号 $number 的画面无法读取：${item.asset.path}');
    }
    return _ShootingScriptShot(
      number: number,
      content: _firstNotEmpty([
        item.caption,
        analysis?.caption,
        analysis?.detail,
      ]),
      shotSize: _templateShotSize(analysis?.shotSize ?? ''),
      cameraMovement: _templateCameraMovement(analysis?.cameraMovement ?? ''),
      pngBytes: prepared['pngBytes']! as Uint8List,
      displayWidth: prepared['displayWidth']! as int,
      displayHeight: prepared['displayHeight']! as int,
    );
  }
}

Map<String, Object> _prepareShootingScriptImage(
  TransferableTypedData transferable, {
  required bool flipHorizontal,
  required bool flipVertical,
}) {
  var image = img.decodeImage(transferable.materialize().asUint8List());
  if (image == null) {
    throw const FormatException('画面无法读取');
  }
  if (flipHorizontal) {
    image = img.flipHorizontal(image);
  }
  if (flipVertical) {
    image = img.flipVertical(image);
  }
  final scale = math.min(
    ShootingScriptExportService._imageWidth / image.width,
    ShootingScriptExportService._imageHeight / image.height,
  );
  return {
    'pngBytes': Uint8List.fromList(img.encodePng(image)),
    'displayWidth': math.max(1, (image.width * scale).round()),
    'displayHeight': math.max(1, (image.height * scale).round()),
  };
}

class _EmbeddedImage {
  const _EmbeddedImage({
    required this.relationshipId,
    required this.imageName,
    required this.row,
    required this.width,
    required this.height,
  });

  final String relationshipId;
  final String imageName;
  final int row;
  final int width;
  final int height;
}

String _firstNotEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}

String _templateShotSize(String value) {
  const allowed = {'全景', '中景', '近景', '特写', '大全景', '远景', '中近景', '大特写'};
  final normalized = value.trim();
  if (allowed.contains(normalized)) {
    return normalized;
  }
  return switch (normalized) {
    '大远景' => '大全景',
    '中近景' => '中近景',
    _ => '',
  };
}

String _templateCameraMovement(String value) {
  const allowed = {
    '推',
    '拉',
    '摇',
    '移',
    '跟',
    '固定',
    '环绕',
    '升降',
    '正跟随',
    '倒跟随',
    '手持',
    '平移',
    '摇移',
  };
  final normalized = value.trim();
  if (allowed.contains(normalized)) {
    return normalized;
  }
  if (normalized.contains('固定')) return '固定';
  if (normalized.contains('正跟')) return '正跟随';
  if (normalized.contains('倒跟')) return '倒跟随';
  if (normalized.contains('平移') || normalized.contains('横移')) return '平移';
  if (normalized.contains('摇移')) return '摇移';
  if (normalized.contains('环绕')) return '环绕';
  if (normalized.contains('升') || normalized.contains('降')) return '升降';
  if (normalized.contains('手持')) return '手持';
  if (normalized.contains('跟')) return '跟';
  if (normalized.contains('推')) return '推';
  if (normalized.contains('拉')) return '拉';
  if (normalized.contains('摇')) return '摇';
  if (normalized.contains('移')) return '移';
  return '';
}
