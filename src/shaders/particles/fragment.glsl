uniform sampler2D uTexture; 
varying vec2 vuv;
varying float vLength; 
uniform vec2 uAspect;
uniform vec2 uTextureSize; 

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void main() {
  vec3 _texture = texture2D(uTexture, vuv).rgb;
  float strength = _texture.r * 0.21 + _texture.g * 0.71 + _texture.b * 0.07;


  gl_FragColor = vec4(vec3(1.0), strength); 
}