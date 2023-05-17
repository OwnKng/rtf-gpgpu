uniform float uTime;
uniform float delta;
uniform vec3 uMouse;

uniform float maxSpeed; 

vec3 updateVelocity(vec3 acceleration, vec3 velocity, float maxSpeed) {
    vec3 newVelocity = velocity + acceleration * delta;
    if (length(newVelocity) > maxSpeed) {
        newVelocity = normalize(newVelocity) * maxSpeed;
    }
    return newVelocity;
}

void main()	{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    vec3 acceleration = texture2D(textureAcceleration, uv).xyz;
  	vec3 velocity = texture2D(textureVelocity, uv).xyz;

    float maxSpeed = texture2D(textureVelocity, uv).w; 

    
    velocity = updateVelocity(acceleration, velocity, maxSpeed);
    acceleration = vec3(0.0);
    
    gl_FragColor = vec4(velocity, 1.0);
}