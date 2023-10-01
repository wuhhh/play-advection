precision mediump float;

// uSmokeDistance: The distance of the smoke from the source
// uDiffuseMult1: The amount of diffusion
// uDiffuseMult2: The amount of diffusion
// uDiffuseDownMult: The amount of down diffusion
// uDiffuseUpMult: The amount of up diffusion

uniform float uSmokeDistance;
uniform float uDiffuseMult1;
uniform float uDiffuseMult2;
uniform float uDiffuseDownMult;
uniform float uDiffuseUpMult;
uniform vec2 uRes; // The width and height of our screen
uniform vec3 uSmokeSource; // The x,y are the posiiton. The z is the power/density
uniform sampler2D uTexture; // Our input texture
uniform sampler2D uVelocityTexture; // Advection / velocity field texture
uniform float uTime; // The time in seconds

varying vec2 vUv;

void main() {
	vec2 fragCoord = gl_FragCoord.xy;
	fragCoord *= 0.5;
	vec2 pixel = fragCoord.xy / uRes.xy;
	gl_FragColor = texture2D( uTexture, pixel );

	// Get the distance of the current pixel from the smoke source
	float dist = distance(uSmokeSource.xy,fragCoord.xy);
	// Generate smoke when mouse is pressed
	gl_FragColor.rgb += uSmokeSource.z * max(uSmokeDistance-dist,0.0);
	// Uncomment for always on painting
	// gl_FragColor.rgb += 0.1 * max(uSmokeDistance-dist,0.0);

	// Smoke diffuse
	float xPixel = 1.0/uRes.x; //The size of a single pixel
	float yPixel = 1.0/uRes.y;
	// Interesting numbers...
	// float xPixel = 1.0/uRes.x * 16.0;//The size of a single pixel
	// float yPixel = 1.0/uRes.y * 2.0;
	vec4 rightColor = texture2D(uTexture,vec2(pixel.x + xPixel, pixel.y));
	vec4 leftColor = texture2D(uTexture,vec2(pixel.x - xPixel, pixel.y));
	vec4 upColor = texture2D(uTexture,vec2(pixel.x, pixel.y + yPixel));
	vec4 downColor = texture2D(uTexture,vec2(pixel.x, pixel.y - yPixel));

	// Handle the bottom boundary 
	if(pixel.y <= yPixel){
		downColor.rgb = vec3(0.0);
	}

	// Diffuse equation
	float factor = 
		uDiffuseMult1 * uDiffuseMult2 * 
			(
				leftColor.r + 
				rightColor.r + 
				downColor.r + 
				upColor.r * uDiffuseDownMult - 
				uDiffuseUpMult * gl_FragColor.r
			);

	// Account for low precision of texels
	// This seems to be unnecessary
	// float minimum = 0.003;
	// if (factor >= -minimum && factor < 0.0) factor = -minimum;

	gl_FragColor.rgb += factor;
}