attribute vec3 position;
attribute vec2 inputTextureCoordinate;
varying vec2 textureCoordinate;

uniform mat4 matrix;

void main (void) {
    textureCoordinate = inputTextureCoordinate;
    gl_Position = matrix * vec4(position.x, -position.y, position.z, 1.0);
}
