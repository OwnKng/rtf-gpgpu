
uniform float time;
uniform sampler2D positionTexture;
uniform vec2 uResolution;

varying vec3 vPosition;
varying vec2 vuv;

attribute vec2 pIndex;
attribute vec3 offset;

varying float vLength; 
uniform vec3 uMouse; 

void main() {
    vec3 pos = texture2D(positionTexture, pIndex).xyz;
    vec3 transposition = position + pos;
    

    vec2 particleuv = pos.xy / uResolution;
    vuv = particleuv + vec2(0.5);

    vec4 mvPosition = modelViewMatrix * vec4(transposition, 1.0);

    vLength = length(pos.xyz - uMouse);
    gl_Position = projectionMatrix * mvPosition;
}