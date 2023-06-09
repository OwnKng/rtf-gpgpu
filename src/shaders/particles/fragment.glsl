varying vec3 vNormal;
varying vec3 vWorldPosition;

uniform vec3 uLightPosition;

float getScatter(vec3 cameraPosition, vec3 direction, vec3 lightPosition, float d) {
  vec3 q = cameraPosition - lightPosition;

  float b = dot(direction, q);
  float c = dot(q, q); 

  float t = c - b * b;
  float s = 1.0 / sqrt(max(0.0001, t));
  float l = s * (atan((d + b) * s) - atan(b * s));

  return pow(max(0.0, l / 15.0), 0.4);
}

void main() {
  vec3 cameraToWorld = vWorldPosition - cameraPosition; 
  vec3 cameraToWorldNormal = normalize(cameraToWorld);
  float cameraToWorldDistance = length(cameraToWorld);

  vec3 lightDirection = normalize(uLightPosition - vWorldPosition);
  float diffusion = max(0.0, dot(vNormal, lightDirection));

  float scatter = getScatter(cameraPosition, cameraToWorldNormal, uLightPosition, cameraToWorldDistance);
  float finalColor = diffusion * scatter;

  gl_FragColor = vec4(finalColor, finalColor, finalColor, 1.0); 
}