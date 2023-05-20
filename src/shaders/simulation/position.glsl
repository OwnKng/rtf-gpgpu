uniform float uTime;
uniform float delta;
uniform vec3 uMouse; 
uniform sampler2D uLifeTexture;

void main()	{

	float r = 10.0; 

    vec2 uv = gl_FragCoord.xy / resolution.xy;
	vec4 tmpPos = texture2D(texturePosition, uv);
	vec3 position = tmpPos.xyz;
	float index = tmpPos.w;
	vec3 velocity = texture2D(textureVelocity, uv).xyz;

	float lifespan = texture2D(uLifeTexture, vec2(uv)).x;

    float distanceFromOrigin = length(position - uMouse);

    if(distanceFromOrigin > lifespan) {
        position = uMouse; 
    } 
    
    gl_FragColor = vec4(position + velocity * delta * 15.0, 1.0);
}