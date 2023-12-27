precision mediump float;

uniform float uAdvDist; // The distance to advect
uniform vec3 uBaseColor; // The base background color
uniform float uColorMode; // Subtractive or additive color mode
uniform float uFactor; // The factor to multiply the color by
uniform vec3 uRGBIntensity; // The intensity of the target color circles
uniform vec3 uRGBRadius; // The radius of the target color circles
uniform vec3 uRGBThroughput; // The throughput of the target color circles
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

	// Set the color of the current pixel to the color of the input texture
	gl_FragColor = texture2D(uTexture, pixel);

	float dist = distance(uSmokeSource.xy, fragCoord.xy);
	float rIntensity = uRGBIntensity.r * 0.01;
	float gIntensity = uRGBIntensity.g * 0.01;
	float bIntensity = uRGBIntensity.b * 0.01;
	float rThroughput = uRGBThroughput.r * 0.01;
	float gThroughput = uRGBThroughput.g * 0.01;
	float bThroughput = uRGBThroughput.b * 0.01;
	
	// Increase the red and blue values of the current pixel by the smoke source power
	gl_FragColor.r += (rIntensity * rThroughput * max(uRGBRadius.r - dist, 0.0)) * uColorMode; // If the dist < 50, add 0.01 to r, radius 50
	gl_FragColor.g += (gIntensity * gThroughput * max(uRGBRadius.g - dist, 0.0)) * uColorMode; // If the dist < 75, add 0.03 to b, radius 75
	gl_FragColor.b += (bIntensity * bThroughput * max(uRGBRadius.b - dist, 0.0)) * uColorMode; // If the dist < 75, add 0.03 to b, radius 75

	// gl_FragColor.r += max(uRGBRadius.r - dist, 0.0) * (sin(uTime * 8.0) + 1.5) * 0.0007;
	// gl_FragColor.g += max(uRGBRadius.g - dist, 0.0) * (sin(uTime * 2.0) + 1.25) * 0.0007;
	// gl_FragColor.b += max(uRGBRadius.b - dist, 0.0) * (sin(uTime * 3.0) + 2.5) * 0.0007;

	float xPixel = 1.0/uRes.x; //The size of a single pixel
	float yPixel = 1.0/uRes.y;

	// Get rb as a vec2, and convert from 0-1 to -1 to 1
	vec2 directionVec = texture2D(uVelocityTexture, pixel.xy).rb * 2.0 - 1.0; 
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

	vec3 factor = (uFactor * 0.001) * (
		leftColor.rgb + 
		rightColor.rgb + 
		downColor.rgb + 
		upColor.rgb - 
		4.0 * gl_FragColor.rgb
	);

	vec3 advected = gl_FragColor.rgb + factor * uColorMode;

	// Clamp depending on the color mode
	if (uColorMode == 1.0) {
		gl_FragColor.r = clamp(advected.r, uBaseColor.r, 1.0);
		gl_FragColor.g = clamp(advected.g, uBaseColor.g, 1.0);
		gl_FragColor.b = clamp(advected.b, uBaseColor.b, 1.0);
	} else {
		gl_FragColor.r = clamp(advected.r, 0.0, uBaseColor.r);
		gl_FragColor.g = clamp(advected.g, 0.0, uBaseColor.g);
		gl_FragColor.b = clamp(advected.b, 0.0, uBaseColor.b);
	}
	
	vec2 advectedPos = pixel - directionVec * uAdvDist * 0.001; // controls the distance of advection
	vec4 advectedColor = texture2D(uTexture, advectedPos);
	vec3 advectedMix = mix(gl_FragColor.rgb, advectedColor.rgb, 0.5);

	gl_FragColor.rgb = advectedMix;
}