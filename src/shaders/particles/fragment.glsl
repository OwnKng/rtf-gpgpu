
varying vec2 vuv;
varying float vLength; 

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void main() {
    vec3 colorOne = vec3(235.0/255.0, 64.0/255.0, 52.0/255.0);
    vec3 colorTwo = vec3(52.0/255.0, 168.0/255.0, 235.0/255.0); 
    float alpha = 1.0 - map(vLength, 0.0, 8.0, 0.0, 1.0);

    vec3 color = mix(colorOne, colorTwo, alpha);

    gl_FragColor = vec4(color, alpha);
}