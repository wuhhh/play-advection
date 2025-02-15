/**
 * Thank you to https://code.tutsplus.com/how-to-write-a-smoke-shader--cms-25587t
 * for the head start it provided :)
 */

 precision mediump float;

//	Classic Perlin 2D Noise 
//	by Stefan Gustavson (https://github.com/stegu/webgl-noise)
//
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec2 fade(vec2 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}

float cnoise(vec2 P){
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
  vec4 norm = 1.79284291400159 - 0.85373472095314 * 
    vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
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

uniform float uAdvDist; // distance to advect
uniform vec3 uBaseColor; // base background color
uniform float uColorMode; // color mode
uniform float uFactor; // factor to multiply color by
uniform float uMouseVelocity; // velocity of mouse
uniform vec3 uRGBIntensity; // intensity of target color circles
uniform vec3 uRGBRadius; // radius of target color circles
uniform vec3 uRGBThroughput; // throughput of target color circles
uniform float uAdvectedMix; // mix of advected color
uniform vec2 uRes; // width and height of screen
uniform vec3 uSmokeSource; // mouse coords, z is power/density
uniform sampler2D uTexture; // input texture
uniform sampler2D uVelocityTexture; // advection / velocity field texture
uniform float uTime; // time in seconds

varying vec2 vUv;

void main() {
	vec2 fragCoord = gl_FragCoord.xy * 0.5;
	vec2 pixel = fragCoord.xy / uRes.xy;

	// Set the color of the current pixel to the color of the input texture
	gl_FragColor = texture2D(uTexture, pixel);

	// float brush = brushance(uSmokeSource.xy, fragCoord.xy); // round
	float brush = abs(fragCoord.x - uSmokeSource.x) + abs(fragCoord.y - uSmokeSource.y); // diamond

	float rIntensity = uRGBIntensity.r * 0.01;
	float gIntensity = uRGBIntensity.g * 0.01;
	float bIntensity = uRGBIntensity.b * 0.01;
	float vel = min(uMouseVelocity, 2.0);
	vel = vel > 0. ? max(vel, 0.75) : 0.0;
	float rThroughput = uRGBThroughput.r * 0.01 * vel;
	float gThroughput = uRGBThroughput.g * 0.01 * vel;
	float bThroughput = uRGBThroughput.b * 0.01 * vel;
	float radiusVelScale = .5;
	float rRadius = uRGBRadius.r * radiusVelScale * vel;
	float gRadius = uRGBRadius.g * radiusVelScale * vel;
	float bRadius = uRGBRadius.b * radiusVelScale * vel;
	
	// Increase the red and blue values of the current pixel by the smoke source power
	gl_FragColor.r += (rIntensity * rThroughput * max(rRadius - brush, 0.0)) * uColorMode; 
	gl_FragColor.g += (gIntensity * gThroughput * max(gRadius - brush, 0.0)) * uColorMode; 
	gl_FragColor.b += (bIntensity * bThroughput * max(bRadius - brush, 0.0)) * uColorMode;

	// vec3 velTex = texture2D(uVelocityTexture, vUv).rgb;
	// vec3 curr = gl_FragColor.rgb;
	// vec3 targ = texture2D(uVelocityTexture, pixel).rgb * max((uRGBRadius.r - dist), 0.0);
	// gl_FragColor.rgb -= (min(curr, targ) - max(curr, targ)) * 0.009 * uColorMode;

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
	float weightMult = 32.;
	rightColor *= rightWeight * weightMult;
	leftColor *= leftWeight * weightMult;
	upColor *= upWeight * weightMult;
	downColor *= downWeight * weightMult;

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
	
	float noiseStrength = .01;
	vec2 noiseOffset = vec2(cnoise(pixel * 20.0 + uTime * .15), cnoise(pixel * 20.0 - uTime * 2.)) * noiseStrength;
	// controls the distance of advection
	vec2 advectedPos = pixel - directionVec * uAdvDist * 0.001 + noiseOffset; // with noise
	// vec2 advectedPos = pixel - directionVec * uAdvDist * 0.001; // without noise
	vec4 advectedColor = texture2D(uTexture, advectedPos);
	vec3 advectedMix = mix(gl_FragColor.rgb, advectedColor.rgb, uAdvectedMix);

	gl_FragColor.rgb = advectedMix;
}