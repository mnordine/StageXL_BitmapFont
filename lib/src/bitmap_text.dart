part of stagexl_bitmapfont;

/// The [BitmapText] is a standard [Bitmap] display object, which generates a
/// a custom [BitmapData] object for a given [text].
///
/// To achieve this, a [RenderTextureQuad] with custom vertices is generated.
/// Please be aware that this is very fast with the WebGL renderer, but slow
/// with the Canvas2D renderer. If you target Canvas2D you should use the
/// [BitmapContainerText] display object.

class BitmapText extends Bitmap {
  final BitmapFont bitmapFont;
  String _text = '';
  HorizontalAlign horizontalAlign = HorizontalAlign.Left;
  num _origX = 0;

  BitmapText(this.bitmapFont) : super() {
    if (bitmapFont.pages.length > 1) {
      throw ArgumentError('Use BitmapContainerText for multi page fonts.');
    }
  }

  @override
  set x(num value) {
    _origX = super.x = value;
    _align();
  }

  //---------------------------------------------------------------------------

  String get text => _text;

  set text(String value) {
    _text = value;
    if (value == '') {
      bitmapData = null;
    } else {
      var renderTextureQuad = bitmapFont.createRenderTextureQuad(text);
      bitmapData = BitmapData.fromRenderTextureQuad(renderTextureQuad);

      _align();
    }
  }

  void _align() {
    switch (horizontalAlign) {
      case HorizontalAlign.Left:   super.x = _origX; break;
      case HorizontalAlign.Center: super.x = _origX - width / 2; break;
      case HorizontalAlign.Right:  super.x = _origX - width; break;
    }
  }
}
