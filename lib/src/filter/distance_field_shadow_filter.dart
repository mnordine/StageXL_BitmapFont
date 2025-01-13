part of stagexl_bitmapfont;

class DistanceFieldShadowFilter extends BitmapFilter {

  /// This configuration of the front distance field
  DistanceFieldConfig frontConfig;

  /// This configuration of the shadow distance field
  DistanceFieldConfig shadowConfig;

  /// The horizontal offset of the shadow.
  num offsetX;

  /// The vertical offset of the shadow.
  num offsetY;

  //---------------------------------------------------------------------------

  DistanceFieldShadowFilter(
      this.frontConfig, this.shadowConfig, this.offsetX, this.offsetY);

  @override
  BitmapFilter clone() {
    var frontConfig = this.frontConfig.clone();
    var shadowConfig = this.shadowConfig.clone();
    return DistanceFieldShadowFilter(
        frontConfig, shadowConfig, offsetX, offsetY);
  }

  //---------------------------------------------------------------------------

  @override
  void apply(BitmapData bitmapData, [Rectangle<num>? rectangle]) {
    // TODO: implement DistanceFieldFilter for BitmapDatas.
  }

  //---------------------------------------------------------------------------

  @override
  void renderFilter(
      RenderState renderState, RenderTextureQuad renderTextureQuad, int pass) {

    RenderContextWebGL renderContext = renderState.renderContext as RenderContextWebGL;
    RenderTexture renderTexture = renderTextureQuad.renderTexture;
    _DistanceFieldFilterProgram renderProgram;

    renderProgram  = renderContext.getRenderProgram(
        r'$DistanceFieldFilterProgram',
        () => _DistanceFieldFilterProgram());

    renderContext.activateRenderProgram(renderProgram);
    renderContext.activateRenderTexture(renderTexture);

    renderState.globalMatrix.prependTranslation(offsetX, offsetY);
    renderProgram.renderDistanceFieldFilterQuad(
        renderState, renderTextureQuad, shadowConfig);

    renderState.globalMatrix.prependTranslation(-offsetX, -offsetY);
    renderProgram.renderDistanceFieldFilterQuad(
        renderState, renderTextureQuad, frontConfig);
  }
}
