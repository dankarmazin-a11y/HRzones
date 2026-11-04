import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// A sheet: a name and rows of cells (String, num, DateTime or null).
class Sheet {
  const Sheet(this.name, this.rows);

  final String name;
  final List<List<Object?>> rows;
}

/// Minimal .xlsx writer (opens in Excel, Numbers, Google Sheets). The first
/// row of each sheet is bold (header) and frozen.
Uint8List buildXlsx(List<Sheet> sheets) {
  final a = Archive();
  void add(String name, String xml) => a.addFile(ArchiveFile.bytes(name, utf8.encode(xml)));

  add('[Content_Types].xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
${[for (var i = 1; i <= sheets.length; i++) '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join('\n')}
</Types>''');
  add('_rels/.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''');
  add('xl/workbook.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets>
${[for (final (i, s) in sheets.indexed) '<sheet name="${_esc(_sheetName(s.name))}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join('\n')}
</sheets>
</workbook>''');
  add('xl/_rels/workbook.xml.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
${[for (var i = 1; i <= sheets.length; i++) '<Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$i.xml"/>'].join('\n')}
<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''');
  // Style 0 = normal, 1 = bold (header), 2 = date-time.
  add('xl/styles.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd hh:mm"/></numFmts>
<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>
<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/><xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/></cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''');
  for (final (i, s) in sheets.indexed) {
    add('xl/worksheets/sheet${i + 1}.xml', _sheetXml(s));
  }
  return ZipEncoder().encodeBytes(a);
}

String _sheetXml(Sheet s) {
  final b = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">')
    ..write(
      '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>',
    )
    ..write('<sheetData>');
  for (final (r, row) in s.rows.indexed) {
    b.write('<row r="${r + 1}">');
    for (final (c, v) in row.indexed) {
      if (v == null) continue;
      final ref = '${_col(c)}${r + 1}';
      final style = r == 0 ? ' s="1"' : '';
      if (v is num) {
        b.write('<c r="$ref"$style><v>$v</v></c>');
      } else if (v is DateTime) {
        b.write('<c r="$ref" s="2"><v>${_excelDate(v)}</v></c>');
      } else {
        b.write('<c r="$ref" t="inlineStr"$style><is><t xml:space="preserve">${_esc(v.toString())}</t></is></c>');
      }
    }
    b.write('</row>');
  }
  b.write('</sheetData></worksheet>');
  return b.toString();
}

/// Excel serial date (days since 1899-12-30), local time.
double _excelDate(DateTime d) {
  final base = DateTime.utc(1899, 12, 30);
  final local = DateTime.utc(d.year, d.month, d.day, d.hour, d.minute, d.second);
  return double.parse((local.difference(base).inSeconds / 86400).toStringAsFixed(6));
}

/// 0 → A, 25 → Z, 26 → AA
String _col(int i) {
  var n = i + 1;
  var s = '';
  while (n > 0) {
    final m = (n - 1) % 26;
    s = String.fromCharCode(65 + m) + s;
    n = (n - 1) ~/ 26;
  }
  return s;
}

String _sheetName(String n) => n.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').substring(0, n.length.clamp(0, 31));

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
