uniform float uTime;
uniform float delta;
uniform sampler2D uLifeTexture;
uniform vec3 uTextureSize; 

void main()	{
    float width = uTextureSize.x; 
    float height = uTextureSize.y;
    float depth = uTextureSize.z;

	float r = 10.0; 

    vec2 uv = gl_FragCoord.xy / resolution.xy;
	vec4 tmpPos = texture2D(texturePosition, uv);
	vec3 position = tmpPos.xyz;
	float index = tmpPos.w;
	vec3 velocity = texture2D(textureVelocity, uv).xyz;

	float lifespan = texture2D(uLifeTexture, vec2(uv)).x;


    // check the position relative to the voundary
    if (position.x < -width * 0.5) {
        position.x = width * 0.5; 
    }

    if (position.x > width * 0.5) {
        position.x = -width * 0.5; 
    }

    if (position.y < -height * 0.5) {
        position.y = height * 0.5; 
    }

    if (position.y > height * 0.5) {
        position.y = -height * 0.5; 
    }

    if (position.z < -depth * 0.5) {
        position.z = depth * 0.5; 
    }

    if (position.z > depth * 0.5) {
        position.z = -depth * 0.5; 
    }

    
    gl_FragColor = vec4(position + velocity * delta * 15.0, 1.0);
}