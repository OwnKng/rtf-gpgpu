uniform vec3 repeller;  
uniform float r; 

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

vec3 seek(vec3 target, vec3 position, vec3 velocity, bool arrival, float maxSpeed, float maxForce) {
    vec3 force = target - position; 
    float desiredSpeed = maxSpeed;
    float r = 10.0; 

    if(arrival) {
        float slowRadius = 2.0;
        // get the length of the vector force
        float d = length(force);

        if(d < r) {
            desiredSpeed = map(d, 0.0, r, 0.0, maxSpeed);
            force = normalize(force) * desiredSpeed;

        } else {
            force = normalize(force) * maxSpeed;
        }
    }

    vec3 steer = force - velocity;

    // limit the force according to maxForce 
    if(length(steer) > maxForce) {
        steer = normalize(steer) * maxForce;
    }

    return steer;
}

vec3 arrive (vec3 target, vec3 position, vec3 velocity, float maxSpeed, float maxForce) {
    return seek(target, position, velocity, true, maxSpeed, maxForce);
}

vec3 flee (vec3 target, vec3 position, vec3 velocity, float maxSpeed, float maxForce) {
    return seek(target, position, velocity, false, maxSpeed, maxForce) * -1.0;
}

vec3 applyForce(vec3 force, vec3 acceleration, float maxForce) {
    if(length(acceleration) > maxForce) {
        acceleration = normalize(acceleration) * maxForce;
    }
    return acceleration + force;
}

void main()	{
    // Get coordinates of particle
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    // Get the velocity and position of the particle
    vec3 position = texture2D(texturePosition, uv).xyz;
    vec3 acceleration = texture2D(textureAcceleration, uv).xyz;
    vec3 velocity = texture2D(textureVelocity, uv).xyz;

    float maxSpeed = texture2D(textureVelocity, uv).w; 
    float maxForce = texture2D(textureAcceleration, uv).w;

    vec3 gravity = vec3(0.0, 0, -0.1);

    float distanceToSphere = length(position - repeller);

    vec3 fleeForce = vec3(0.0);

    if(distanceToSphere < r) {
        fleeForce += flee(repeller, position, velocity, maxSpeed, maxForce);
    }

    acceleration = applyForce(gravity, acceleration, maxForce);
    acceleration = applyForce(fleeForce, acceleration, maxForce);

    // Return acceleration
    gl_FragColor = vec4(acceleration, 1.0);
}