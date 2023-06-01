#define PHONG
uniform sampler2D positionTexture;
uniform sampler2D velocityTexture;
attribute vec2 pIndex;
attribute vec3 offset;

varying vec3 vViewPosition;

#include <common>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>

void main() {

	#include <uv_vertex>
	#include <color_vertex>
	#include <morphcolor_vertex>

	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>

	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>

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

	
	vViewPosition = - mvPosition.xyz;
    mvPosition = modelViewMatrix * vec4(newPositon, 1.0);

	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>

    gl_Position = projectionMatrix * viewMatrix * vec4(newPositon, 1.0);
}
