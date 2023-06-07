uniform float uTime;
uniform float delta;
uniform vec3 uMouse;
uniform sampler2D uLifeTexture;
uniform sampler2D uStartingVelocity;

uniform vec3 predators[2];

vec4 permute(vec4 x) {
    return mod(((x*34.0)+1.0)*x, 289.0);
}

vec2 fade(vec2 t) {
    return t*t*t*(t*(t*6.0-15.0)+10.0);
}

float cnoise(vec2 P) {
    vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
    vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
    Pi = mod(Pi, 289.0); // To avoid truncation effects in permutation
    vec4 ix = Pi.xzxz;
    vec4 iy = Pi.yyww;
    vec4 fx = Pf.xzxz;
    vec4 fy = Pf.yyww;
    vec4 i = permute(permute(ix) + iy);
    vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
    vec4 gy = abs(gx) - 0.5;
    vec4 tx = floor(gx + 0.5);
    gx = gx - tx;
    vec2 g00 = vec2(gx.x,gy.x);
    vec2 g10 = vec2(gx.y,gy.y);
    vec2 g01 = vec2(gx.z,gy.z);
    vec2 g11 = vec2(gx.w,gy.w);
    vec4 norm = 1.79284291400159 - 0.85373472095314 * vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
    g00 *= norm.x;
    g01 *= norm.y;
    g10 *= norm.z;
    g11 *= norm.w;
    float n00 = dot(g00, vec2(fx.x, fy.x));
    float n10 = dot(g10, vec2(fx.y, fy.y));
    float n01 = dot(g01, vec2(fx.z, fy.z));
    float n11 = dot(g11, vec2(fx.w, fy.w));
    vec2 fade_xy = fade(Pf.xy);
    vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
    float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
    return 2.3 * n_xy;
}


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

vec3 arrive(vec3 target, vec3 position, vec3 velocity, float maxSpeed, float maxForce) {
    return seek(target, position, velocity, true, maxSpeed, maxForce);
}

vec3 flee(vec3 target, vec3 position, vec3 velocity, float maxSpeed, float maxForce) {
    return seek(target, position, velocity, false, maxSpeed, maxForce) * -1.0;
}

vec3 separate(vec3 position, vec3 velocity, float maxSpeed, float maxForce, float width, float height) {
    vec3 steer = vec3(0.0);
    vec3 sum = vec3(0.0);

    float count = 0.0;
    float desiredSeparation = 0.8;

    for(float y = 0.0; y < height; y++) {
        for(float x = 0.0; x < width; x++) {
            vec2 ref = vec2(x + 0.5, y + 0.5) / resolution.xy;
            vec3 boidPosition = texture2D(texturePosition, ref).xyz;

            float d = distance(position, boidPosition);

            if(d > 0.0 && d < desiredSeparation) {
                vec3 diff = position - boidPosition;
                diff = normalize(diff);
                diff /= d;
                sum += diff;
                count++;
            }
        }
    }

    if(count > 0.0) {
        sum /= count;
        sum = normalize(sum);
        sum *= maxSpeed;
        steer = sum - velocity;
        if(length(steer) > maxForce) {
            steer = normalize(steer) * maxForce;
        }
    }

    return steer;
}

vec3 align (vec3 position, vec3 velocity, float maxSpeed, float maxForce, float width, float height) {
    vec3 steer = vec3(0.0);
    vec3 sum = vec3(0.0);

    float count = 0.0;
    float neighborhoodDistance = 1.0; 

    for(float y = 0.0; y < height; y++) {
        for(float x = 0.0; x < width; x++) {
            vec2 ref = vec2(x + 0.5, y + 0.5) / resolution.xy;
            vec3 boidPosition = texture2D(texturePosition, ref).xyz;

            float d = distance(position, boidPosition);

            if(d > 0.0 && d < neighborhoodDistance) {
                vec3 boidVelocity = texture2D(textureVelocity, ref).xyz;
                sum += boidVelocity;
                count++;
            }
        }
    }

    if(count > 0.0) {
        sum /= count;
        sum = normalize(sum);
        sum *= maxSpeed;
        steer = sum - velocity;
        if(length(steer) > maxForce) {
            steer = normalize(steer) * maxForce;
        }
    }

    return steer;
}

vec3 cohere(vec3 position, vec3 velocity, float maxSpeed, float maxForce, float width, float height) {
    vec3 steer = vec3(0.0);
    vec3 sum = vec3(0.0);

    float count = 0.0;
    float neighborhoodDistance = 1.0;

    float numberOfBoids = 0.0; 

    for(float y = 0.0; y < height; y++) {
        for(float x = 0.0; x < width; x++) {
            vec2 ref = vec2(x + 0.5, y + 0.5) / resolution.xy;
            vec3 boidPosition = texture2D(texturePosition, ref).xyz;

            float d = distance(position, boidPosition);
            numberOfBoids ++; 

            if(d > 0.0 && d < neighborhoodDistance) {
                sum += boidPosition;
                count++;
            }
        }
    }

    if(count > 0.0) {
        sum /= numberOfBoids;
        steer = seek(sum, position, velocity, false, maxSpeed, maxForce);
    }

    return steer;
}

vec3 applyForce(vec3 force, vec3 acceleration, float maxForce) {
    if(length(acceleration) > maxForce) {
        acceleration = normalize(acceleration) * maxForce;
    }
    return acceleration + force;
}

vec3 updateVelocity(vec3 acceleration, vec3 velocity, float maxSpeed) {
    vec3 newVelocity = velocity + acceleration * delta;
    if (length(newVelocity) > maxSpeed) {
        newVelocity = normalize(newVelocity) * maxSpeed;
    }
    return newVelocity;
}

    float random(vec2 co) {
	return (fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453) - 0.5) * 2.0;
}

vec3 randomVector(vec2 co) {
	return vec3(random(vec2(co.x * co.y, 0.0)), random(vec2(0.0, co.x * co.y)), 0.0);
}

void main()	{
    float width = resolution.x;
    float height = resolution.y;

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 position = texture2D(texturePosition, uv).xyz;
    float index = texture2D(texturePosition, uv).w;
    vec3 velocity = texture2D(textureVelocity, uv).xyz;

    float lifespan = texture2D(uLifeTexture, vec2(uv)).x;
    float maxSpeed = texture2D(uLifeTexture, vec2(uv)).y;
    float maxForce = texture2D(uLifeTexture, vec2(uv)).z;

    vec3 acceleration = vec3(0.0);

    vec3 separation = separate(position, velocity, maxSpeed, maxForce, width, height);
    acceleration += applyForce(separation, acceleration, maxForce);

    vec3 alignment = align(position, velocity, maxSpeed, maxForce, width, height);
    acceleration += applyForce(alignment, acceleration, maxForce);

    vec3 cohesion = cohere(position, velocity, maxSpeed, maxForce, width, height);
    acceleration += applyForce(cohesion, acceleration, maxForce);

    vec3 target = vec3(0.0, 0.0, 0.0);
    // get distance to center
    float distanceToCenter = length(position);
    float r = 15.0; 

    if(distanceToCenter > r) {
        vec3 seekForce = seek(target, position, velocity, true, maxSpeed, maxForce);
        acceleration += applyForce(seekForce, acceleration, maxForce);
    }

    // iterate through the predators positions, and apply a force to avoid them
    for(int i = 0; i < 2; i++) {
        vec3 predator = predators[i];
        float distanceToPredator = length(position - predator);

        if(distanceToPredator < 4.0) {
            vec3 force = flee(predator, position, velocity, maxSpeed, maxForce);
            force *= 10.0;
            acceleration += applyForce(force, acceleration, maxForce);
        }
    }

    velocity = updateVelocity(acceleration, velocity, maxSpeed);
    gl_FragColor = vec4(velocity, 1.0);
}