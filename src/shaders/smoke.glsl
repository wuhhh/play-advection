precision mediump float;

// uniform float uSmokeDistance;
// uniform float uDiffuseMult1;
// uniform float uDiffuseMult2;
// uniform float uDiffuseDownMult;
// uniform float uDiffuseUpMult;
uniform vec2 uRes; // The width and height of our screen
uniform vec3 uSmokeSource; // The x,y are the posiiton. The z is the power/density
uniform sampler2D uTexture; // Our input texture
uniform sampler2D uVelocityTexture; // Advection / velocity field texture
uniform float uTime; // The time in seconds

varying vec2 vUv;

void main() {
	vec2 mouse = uSmokeSource.xy / uRes.xy;
	vec2 fragCoord = gl_FragCoord.xy * 0.5;
	vec2 pixel = fragCoord.xy / uRes.xy;
	gl_FragColor = texture2D(uTexture, pixel);

	float dist = distance(uSmokeSource.xy, fragCoord.xy);
	
	gl_FragColor.r += uSmokeSource.z * 0.02 * max(50.0 - dist, 0.0); // If the dist < 50, add 0.01 to r, radius 50
	gl_FragColor.b += uSmokeSource.z * 0.03 * max(75.0 - dist, 0.0); // If the dist < 75, add 0.03 to b, radius 75

	float xPixel = 1.0/uRes.x; //The size of a single pixel
	float yPixel = 1.0/uRes.y;

	vec2 directionVec = texture2D(uVelocityTexture, pixel.xy).rb * 2.0 - 1.0; // Get rb as a vec2, and convert from 0-1 to -1 to 1
	directionVec = normalize(directionVec);

	// Get vector directions for each pixel around the current pixel
	vec2 rightVec = vec2(xPixel, 0.0);
	vec2 leftVec = vec2(-xPixel, 0.0);
	vec2 upVec = vec2(0.0, yPixel);
	vec2 downVec = vec2(0.0, -yPixel);

	// Get the weights of each pixel according to the direction
	float rightWeight = dot(directionVec, normalize(rightVec));
	float leftWeight = dot(directionVec, normalize(leftVec));
	float upWeight = dot(directionVec, normalize(upVec));
	float downWeight = dot(directionVec, normalize(downVec));

	// Get positions of each pixel around the current pixel
	vec2 rightPixel = vec2(pixel.x + xPixel, pixel.y);
	vec2 leftPixel = vec2(pixel.x - xPixel, pixel.y);
	vec2 upPixel = vec2(pixel.x, pixel.y + yPixel);
	vec2 downPixel = vec2(pixel.x, pixel.y - yPixel);
	
	// Sample the colors of each pixel around the current pixel
	vec4 rightColor = texture2D(uTexture,vec2(rightPixel));
	vec4 leftColor = texture2D(uTexture,vec2(leftPixel));
	vec4 upColor = texture2D(uTexture,vec2(upPixel));
	vec4 downColor = texture2D(uTexture,vec2(downPixel));

	// Multiply the colors by the weights
	// The more aligned the direction is with the pixel, the higher the weight
	rightColor *= rightWeight;
	leftColor *= leftWeight;
	upColor *= upWeight;
	downColor *= downWeight;

	vec3 factor = 0.001 * (
		leftColor.rgb + 
		rightColor.rgb + 
		downColor.rgb + 
		upColor.rgb - 
		4.0 * gl_FragColor.rgb
	);

	gl_FragColor.rgb += factor;
	vec2 advectedPos = pixel - directionVec * 0.001; // some_constant controls the distance of advection
	vec4 advectedColor = texture2D(uTexture, advectedPos);
	vec3 advectedMix = mix(gl_FragColor.rgb, advectedColor.rgb, 0.5);

	gl_FragColor.rgb = advectedMix;


	// gl_FragColor.rgb += factor;
}