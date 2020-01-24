precision highp float;

uniform sampler2D renderTexture;
varying vec2 textureCoordinate;

void main (void) {
    gl_FragColor = texture2D(renderTexture, textureCoordinate);
}

