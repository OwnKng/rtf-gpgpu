uniform sampler2D positionTexture;
uniform sampler2D velocityTexture;
attribute vec2 pIndex;
attribute vec3 offset;

varying vec3 vViewPosition;
varying vec3 vWorldPosition;
varying vec3 vNormal; 

void main() {
    vec3 tempPosition = texture2D(positionTexture, pIndex).xyz;
	vec3 velocity = normalize(texture2D(velocityTexture, pIndex).xyz);

	vec3 newPositon = position; 
	newPositon = mat3(modelMatrix) * newPositon;

	velocity.z *= -1.0; 
	float xz = length(velocity.xz);
	float xyz = 1.0; 
	float x = sqrt(1.0 - velocity.y * velocity.y);

	float cosry = velocity.x / xz;
	float sinry = velocity.z / xz;

	float cosrz = x / xyz;
	float sinrz = velocity.y / xyz;

	mat3 maty = mat3(cosry, 0, -sinry, 0, 1, 0, sinry, 0, cosry);
	mat3 matz = mat3(cosrz, sinrz, 0, -sinrz, cosrz, 0, 0, 0, 1);

	newPositon = maty * matz * newPositon;
	newPositon += tempPosition; 

	vec4 mvPosition = modelViewMatrix * vec4(newPositon, 1.0);
	vViewPosition = - mvPosition.xyz;

	vNormal = normalize(normalMatrix * normal);

	vWorldPosition = newPositon;
    gl_Position = projectionMatrix * viewMatrix * vec4(newPositon, 1.0);
}
