
uniform float time;
uniform sampler2D positionTexture;
 
varying vec3 vPosition;
varying vec2 vuv;

attribute vec2 pIndex;
attribute vec3 offset;

void main() {
    vec3 pos = texture2D(positionTexture, pIndex).xyz;
    vec3 transposition = position + pos;

    vuv = pIndex;
    vec4 mvPosition = modelViewMatrix * vec4(transposition, 1.0);
 
    gl_Position = projectionMatrix * mvPosition;
}