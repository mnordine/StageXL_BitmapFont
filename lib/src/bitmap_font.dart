part of stagexl_bitmapfont;

class BitmapFont {
  /// Information on how the font was generated.
  final BitmapFontInfo info;

  /// Information common to all characters.
  final BitmapFontCommon common;

  /// The pages (textures) used for this characters.
  final List<BitmapFontPage> pages;

  /// The characters in the font.
  final List<BitmapFontChar> chars;

  /// The kerning information is used to adjust the distance between certain characters,
  /// e.g. some characters should be placed closer to each other than others.
  final List<BitmapFontKerning> kernings;

  final double pixelRatio;

  BitmapFont(this.info, this.common, this.pages, this.chars, this.kernings,
      this.pixelRatio);

  //---------------------------------------------------------------------------

  static Future<BitmapFont> load(String url,
          [BitmapFontFormat bitmapFontFormat = BitmapFontFormat.FNT,
          BitmapDataLoadOptions? bitmapDataLoadOptions]) =>
      bitmapFontFormat.load(_BitmapFontLoaderFile(url, bitmapDataLoadOptions));

  static Future<BitmapFont> fromTextureAtlas(
          TextureAtlas textureAtlas, String namePrefix, String source,
          [BitmapFontFormat bitmapFontFormat = BitmapFontFormat.FNT]) =>
      bitmapFontFormat.load(
          _BitmapFontLoaderTextureAtlas(textureAtlas, namePrefix, source));

  static Future<BitmapFont> fromBitmapData(BitmapData bitmapData, String source,
          [BitmapFontFormat bitmapFontFormat = BitmapFontFormat.FNT]) =>
      bitmapFontFormat.load(_BitmapFontLoaderBitmapData(bitmapData, source));

  static Future<BitmapFont> withLoader(BitmapFontLoader bitmapFontLoader,
          [BitmapFontFormat bitmapFontFormat = BitmapFontFormat.FNT]) =>
      bitmapFontFormat.load(bitmapFontLoader);

  //---------------------------------------------------------------------------

  BitmapFontChar? getChar(int id) {
    for (var i = 0; i < chars.length; i++) {
      var char = chars[i];
      if (char.id == id) return char;
    }
    return null;
  }

  BitmapFontKerning? getKerning(int first, int second) {
    for (var i = 0; i < kernings.length; i++) {
      var kerning = kernings[i];
      if (kerning.first == first && kerning.second == second) {
        return kerning;
      }
    }
    return null;
  }

  int getKerningAmount(int first, int second) {
    var kerning = getKerning(first, second);
    return kerning != null ? kerning.amount : 0;
  }

  //---------------------------------------------------------------------------

  RenderTextureQuad createRenderTextureQuad(String text) {
    if (pages.length != 1) {
      throw StateError('Not supported for multi page bitmap fonts.');
    }

    var ixOffset = 0;
    var lastCodeUnit = 0;

    var scale = 1.0 / pixelRatio;
    var maxX = 0.0;
    var x = 0.0;
    var y = 0.0;

    var lineSplit = RegExp(r'\r\n|\r|\n');
    var vxData = <double>[];
    var ixData = <int>[];

    for (var line in text.split(lineSplit)) {
      for (var codeUnit in line.codeUnits) {
        x += scale * getKerningAmount(lastCodeUnit, codeUnit);

        var bitmapFontChar = getChar(codeUnit);
        if (bitmapFontChar == null) continue;

        var charQuad = bitmapFontChar.bitmapData.renderTextureQuad;
        var charVxList = charQuad.vxList;
        var charIxList = charQuad.ixList;

        for (var i = 0; i < charIxList.length; i++) {
          ixData.add(ixOffset + charIxList[i]);
        }

        for (var i = 0; i <= charVxList.length - 4; i += 4) {
          vxData.add(charVxList[i + 0] + x);
          vxData.add(charVxList[i + 1] + y);
          vxData.add(charVxList[i + 2]);
          vxData.add(charVxList[i + 3]);
          ixOffset += 1;
        }

        x += scale * bitmapFontChar.advance;
        lastCodeUnit = codeUnit;
      }

      maxX = x > maxX ? x : maxX;
      lastCodeUnit = 0;
      x = 0.0;
      y = y + scale * common.lineHeight;
    }

    var bounds = Rectangle<num>(0, 0, maxX, y);
    var renderTexture = pages[0].bitmapData.renderTexture;
    var renderTextureQuad = renderTexture.quad.cut(bounds);
    var vxList = Float32List.fromList(vxData);
    var ixList = Int16List.fromList(ixData);
    renderTextureQuad.setCustomVertices(vxList, ixList);

    return renderTextureQuad;
  }
}
