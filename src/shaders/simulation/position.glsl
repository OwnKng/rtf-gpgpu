uniform float uTime;
uniform float delta;

float random(vec2 co) {
	return (fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453) - 0.5) * 2.0;
}

vec3 randomVector(vec2 co) {
	return vec3(random(vec2(co.x * co.y, 0.0)), random(vec2(0.0, co.x * co.y)), random(vec2(0.0, 0.0)));
}

void main()	{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
	vec4 tmpPos = texture2D(texturePosition, uv);
	vec3 position = tmpPos.xyz;
	float index = tmpPos.w;
	vec3 velocity = texture2D(textureVelocity, uv).xyz;
	float lifespan = texture2D(texturePosition, uv).w;

	if (position.z < -2.5 - lifespan) {
		position = vec3(0.0, 0.0, 5.0);
		velocity = randomVector(vec2(uTime, index)) * 0.1;
	}
    
    gl_FragColor = vec4(position + velocity * delta * 15.0, 1.0);
}