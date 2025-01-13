part of stagexl_bitmapfont;

class _BitmapFontLoaderFile extends BitmapFontLoader {
  late BitmapDataLoadOptions _loadOptions;
  late BitmapDataLoadInfo _loadInfo;

  _BitmapFontLoaderFile(String sourceUrl, BitmapDataLoadOptions? options) {
    _loadOptions = options ?? BitmapData.defaultLoadOptions;
    _loadInfo = BitmapDataLoadInfo(sourceUrl, _loadOptions.pixelRatios);
  }

  //----------------------------------------------------------------------------

  @override
  double getPixelRatio() => _loadInfo.pixelRatio;

  @override
  Future<String> getSource() => http.get(Uri.parse(_loadInfo.loaderUrl)).then((response) => response.body);

  @override
  Future<BitmapData> getBitmapData(int id, String filename) async {
    var loaderUrl = _loadInfo.loaderUrl;
    var pixelRatio = _loadInfo.pixelRatio;
    var regex = RegExp(r'^(.*/)?(?:$|(.+?)(?:(\.[^.]*$)|$))');
    var path = regex.firstMatch(loaderUrl)?.group(1);
    var imageUrl = path == null ? filename : '$path$filename';
    var bitmap = await BitmapData.load(imageUrl, _loadOptions);
    var renderTextureQuad = bitmap.renderTextureQuad.withPixelRatio(pixelRatio);
    return BitmapData.fromRenderTextureQuad(renderTextureQuad);
  }
}
