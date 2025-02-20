part of stagexl_bitmapfont;

class DistanceFieldOutlineFilter extends BitmapFilter {
  /// This configuration of the inner distance field;
  DistanceFieldConfig innerConfig;

  /// This configuration of the outer distance field;
  DistanceFieldConfig outerConfig;

  //---------------------------------------------------------------------------

  DistanceFieldOutlineFilter(this.innerConfig, this.outerConfig);

  @override
  BitmapFilter clone() {
    var innerConfig = this.innerConfig.clone();
    var outerConfig = this.outerConfig.clone();
    return DistanceFieldOutlineFilter(innerConfig, outerConfig);
  }

  //---------------------------------------------------------------------------

  @override
  void apply(BitmapData bitmapData, [Rectangle<num>? rectangle]) {
    // TODO: implement DistanceFieldOutlineFilter for BitmapDatas.
  }

  //---------------------------------------------------------------------------

  @override
  void renderFilter(
      RenderState renderState, RenderTextureQuad renderTextureQuad, int pass) {
    var renderContext = renderState.renderContext as RenderContextWebGL;
    var renderTexture = renderTextureQuad.renderTexture;
    _DistanceFieldOutlineFilterProgram renderProgram;

    renderProgram = renderContext.getRenderProgram(
        r'$DistanceFieldOutlineFilterProgram',
        () => _DistanceFieldOutlineFilterProgram());

    renderContext.activateRenderProgram(renderProgram);
    renderContext.activateRenderTexture(renderTexture);
    renderProgram.renderDistanceFieldOutlineFilterQuad(
        renderState, renderTextureQuad, this);
  }
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

class _DistanceFieldOutlineFilterProgram extends RenderProgram {
  // aPosition:   Float32(x), Float32(y)
  // aTexCoord:   Float32(u), Float32(v)
  // aInnerColor: Float32(r), Float32(g), Float32(b), Float32(a)
  // aOuterColor: Float32(r), Float32(g), Float32(b), Float32(a)
  // aThreshold:  Float32(innerThresholdMin), Float32(innerThresholdMax),
  //              Float32(outerThresholdMin), Float32(outerThresholdMax),

  @override
  String get vertexShaderSource => '''

    uniform mat4 uProjectionMatrix;

    attribute vec2 aPosition;
    attribute vec2 aTexCoord;
    attribute vec4 aInnerColor;
    attribute vec4 aOuterColor;
    attribute vec4 aThreshold;

    varying vec2 vTexCoord;
    varying vec4 vInnerColor;
    varying vec4 vOuterColor;
    varying vec4 vThreshold;

    void main() {
      vTexCoord = aTexCoord;
      vThreshold = aThreshold;
      vInnerColor = vec4(aInnerColor.rgb * aInnerColor.a, aInnerColor.a);
      vOuterColor = vec4(aOuterColor.rgb * aOuterColor.a, aOuterColor.a);
      gl_Position = vec4(aPosition, 0.0, 1.0) * uProjectionMatrix;
    }
    ''';

  @override
  String get fragmentShaderSource => '''

    precision mediump float;
    uniform sampler2D uSampler;

    varying vec2 vTexCoord;
    varying vec4 vInnerColor;
    varying vec4 vOuterColor;
    varying vec4 vThreshold;

    void main() {
      vec2 distance = texture2D(uSampler, vTexCoord).aa;
      vec2 alpha = smoothstep(vThreshold.xz, vThreshold.yw, distance);
      vec4 innerColor = vInnerColor * alpha.x;
      vec4 outerColor = vOuterColor * max(alpha.y - alpha.x, 0.0);
      gl_FragColor = innerColor + outerColor;
    }
    ''';

  //---------------------------------------------------------------------------

  @override
  void activate(RenderContextWebGL renderContext) {
    super.activate(renderContext);

    renderingContext.uniform1i(uniforms['uSampler'], 0);
  }

  @override
  void setupAttributes() {
    renderBufferVertex.bindAttribute(attributes['aPosition'], 2, 64, 0);
    renderBufferVertex.bindAttribute(attributes['aTexCoord'], 2, 64, 8);
    renderBufferVertex.bindAttribute(attributes['aInnerColor'], 4, 64, 16);
    renderBufferVertex.bindAttribute(attributes['aOuterColor'], 4, 64, 32);
    renderBufferVertex.bindAttribute(attributes['aThreshold'], 4, 64, 48);
  }

  //---------------------------------------------------------------------------

  void renderDistanceFieldOutlineFilterQuad(
      RenderState renderState,
      RenderTextureQuad renderTextureQuad,
      DistanceFieldOutlineFilter distanceFieldOutlineFilter) {
    var alpha = renderState.globalAlpha;
    var matrix = renderState.globalMatrix;
    var ixList = renderTextureQuad.ixList;
    var vxList = renderTextureQuad.vxList;
    var indexCount = ixList.length;
    var vertexCount = vxList.length >> 2;
    var scale = math.sqrt(matrix.det);

    // setup

    var inner = distanceFieldOutlineFilter.innerConfig;
    var innerColorA = ((inner.color >> 24) & 0xFF) / 255.0 * alpha;
    var innerColorR = ((inner.color >> 16) & 0xFF) / 255.0;
    var innerColorG = ((inner.color >> 8) & 0xFF) / 255.0;
    var innerColorB = ((inner.color >> 0) & 0xFF) / 255.0;
    var innerThresholdMin = inner.threshold - inner.softness / scale;
    var innerThresholdMax = inner.threshold + inner.softness / scale;
    if (innerThresholdMin < 0.0) innerThresholdMin = 0.0;
    if (innerThresholdMax > 1.0) innerThresholdMax = 1.0;

    var outer = distanceFieldOutlineFilter.outerConfig;
    var outerColorA = ((outer.color >> 24) & 0xFF) / 255.0 * alpha;
    var outerColorR = ((outer.color >> 16) & 0xFF) / 255.0;
    var outerColorG = ((outer.color >> 8) & 0xFF) / 255.0;
    var outerColorB = ((outer.color >> 0) & 0xFF) / 255.0;
    var outerThresholdMin = outer.threshold - outer.softness / scale;
    var outerThresholdMax = outer.threshold + outer.softness / scale;
    if (outerThresholdMin < 0.0) outerThresholdMin = 0.0;
    if (outerThresholdMax > 1.0) outerThresholdMax = 1.0;

    // check buffer sizes and flush if necessary

    var ixData = renderBufferIndex.data;
    var ixPosition = renderBufferIndex.position;
    if (ixPosition + indexCount >= ixData.length) flush();

    var vxData = renderBufferVertex.data;
    var vxPosition = renderBufferVertex.position;
    if (vxPosition + vertexCount * 16 >= vxData.length) flush();

    var ixIndex = renderBufferIndex.position;
    var vxIndex = renderBufferVertex.position;
    var vxCount = renderBufferVertex.count;

    // copy index list

    for (var i = 0; i < indexCount; i++) {
      ixData[ixIndex + i] = vxCount + ixList[i];
    }

    renderBufferIndex.position += indexCount;
    renderBufferIndex.count += indexCount;

    // copy vertex list

    var ma = matrix.a;
    var mb = matrix.b;
    var mc = matrix.c;
    var md = matrix.d;
    var mx = matrix.tx;
    var my = matrix.ty;

    for (var i = 0, o = 0; i < vertexCount; i++, o += 4) {
      var x = vxList[o + 0];
      var y = vxList[o + 1];
      vxData[vxIndex + 00] = mx + ma * x + mc * y;
      vxData[vxIndex + 01] = my + mb * x + md * y;
      vxData[vxIndex + 02] = vxList[o + 2];
      vxData[vxIndex + 03] = vxList[o + 3];
      vxData[vxIndex + 04] = innerColorR;
      vxData[vxIndex + 05] = innerColorG;
      vxData[vxIndex + 06] = innerColorB;
      vxData[vxIndex + 07] = innerColorA;
      vxData[vxIndex + 08] = outerColorR;
      vxData[vxIndex + 09] = outerColorG;
      vxData[vxIndex + 10] = outerColorB;
      vxData[vxIndex + 11] = outerColorA;
      vxData[vxIndex + 12] = innerThresholdMin;
      vxData[vxIndex + 13] = innerThresholdMax;
      vxData[vxIndex + 14] = outerThresholdMin;
      vxData[vxIndex + 15] = outerThresholdMax;
      vxIndex += 16;
    }

    renderBufferVertex.position += vertexCount * 16;
    renderBufferVertex.count += vertexCount;
  }
}
