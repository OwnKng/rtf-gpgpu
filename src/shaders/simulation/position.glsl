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
    
    gl_FragColor = vec4(position + velocity * delta * 15.0, 1.0);
}