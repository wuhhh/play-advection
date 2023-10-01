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
// uniform float uTime; // The time in seconds

varying vec2 vUv;

void main() {
	vec2 mouse = uSmokeSource.xy / uRes.xy;

	vec2 fragCoord = gl_FragCoord.xy;
	fragCoord *= 0.5;
	vec2 pixel = fragCoord.xy / uRes.xy;
	gl_FragColor = texture2D( uTexture, pixel );

	float dist = distance(uSmokeSource.xy,fragCoord.xy);
	gl_FragColor.rgb += uSmokeSource.z * 0.1 * max(30.0-dist,0.0);

	float xPixel = 1.0/uRes.x; //The size of a single pixel
	float yPixel = 1.0/uRes.y;
	// float xPixel = 1.0/uRes.x * 16.0;//The size of a single pixel
	// float yPixel = 1.0/uRes.y * 16.0;

	vec4 vectorTexel = texture2D(uVelocityTexture,vec2(pixel.xy));
	vec2 directionVec = texture2D(uVelocityTexture, pixel.xy).rb * 2.0 - 1.0;
	directionVec = normalize(directionVec);

	vec2 rightVec = vec2(xPixel, 0.0);
	vec2 leftVec = vec2(-xPixel, 0.0);
	vec2 upVec = vec2(0.0, yPixel);
	vec2 downVec = vec2(0.0, -yPixel);

	float rightWeight = dot(directionVec, normalize(rightVec));
	float leftWeight = dot(directionVec, normalize(leftVec));
	float upWeight = dot(directionVec, normalize(upVec));
	float downWeight = dot(directionVec, normalize(downVec));

	// float rightDot = dot(vec2(1.0, 0.0), vectorTexel.rb);
	// float leftDot = dot(vec2(-1.0, 0.0), vectorTexel.rb);
	// float upDot = dot(vec2(0.0, 1.0), vectorTexel.rb);
	// float downDot = dot(vec2(0.0, -1.0), vectorTexel.rb);

	vec2 rightPixel = vec2(pixel.x + xPixel, pixel.y);
	vec2 leftPixel = vec2(pixel.x - xPixel, pixel.y);
	vec2 upPixel = vec2(pixel.x, pixel.y + yPixel);
	vec2 downPixel = vec2(pixel.x, pixel.y - yPixel);
	
	vec4 rightColor = texture2D(uTexture,vec2(rightPixel));
	vec4 leftColor = texture2D(uTexture,vec2(leftPixel));
	vec4 upColor = texture2D(uTexture,vec2(upPixel));
	vec4 downColor = texture2D(uTexture,vec2(downPixel));

	// rightColor *= clamp(rightDot, 0.0, 1.0) * 5.0;
	// leftColor *= clamp(leftDot, 0.0, 1.0);
	// upColor *= clamp(upDot, 0.0, 1.0) * 5.0;

	float mult = 10.0;
	rightColor *= (rightWeight * mult);
	leftColor *= (leftWeight * mult);
	upColor *= (upWeight * mult);
	downColor *= (downWeight * mult);

	vec3 factor = 
		0.01 * 
			(
				leftColor.rgb + 
				rightColor.rgb + 
				downColor.rgb + 
				upColor.rgb - 
				4.0 * gl_FragColor.rgb
			);

	vec2 advectedPos = pixel - directionVec * 0.001; // some_constant controls the distance of advection
	vec4 advectedColor = texture2D(uTexture, advectedPos);
	gl_FragColor.rgb = mix(gl_FragColor.rgb, advectedColor.rgb, 0.5);


	// gl_FragColor.rgb += factor;
}