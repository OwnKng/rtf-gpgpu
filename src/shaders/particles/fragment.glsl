uniform sampler2D uTexture; 
varying vec2 vuv;
varying float vLength; 

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void main() {
  gl_FragColor = vec4(vec3(1.0), 0.5); 
}