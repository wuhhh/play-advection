precision mediump float;

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
	vec2 mouse = uSmokeSource.xy / uRes.xy;

	vec2 fragCoord = gl_FragCoord.xy;
	fragCoord *= 0.5;
	vec2 pixel = fragCoord.xy / uRes.xy;
	gl_FragColor = texture2D( uTexture, pixel );

	float dist = distance(uSmokeSource.xy,fragCoord.xy);
	gl_FragColor.b += uSmokeSource.z * 0.5 * max(30.0-dist,0.0);

	// float xPixel = 1.0/uRes.x; //The size of a single pixel
	// float yPixel = 1.0/uRes.y;
	float xPixel = 1.0/uRes.x * 16.0;//The size of a single pixel
	float yPixel = 1.0/uRes.y * 16.0;

	float sinTime = sin(uTime * 4.0);

	// 
	vec4 vectorTexel = texture2D(uVelocityTexture,vec2(pixel.xy));

	
	vec4 rightColor = texture2D(uTexture,vec2(pixel.x + xPixel, pixel.y));
	vec4 leftColor = texture2D(uTexture,vec2(pixel.x - xPixel, pixel.y));
	vec4 upColor = texture2D(uTexture,vec2(pixel.x, pixel.y + yPixel));
	vec4 downColor = texture2D(uTexture,vec2(pixel.x, pixel.y - yPixel));

	if(pixel.y <= yPixel){
		downColor.rgb = vec3(0.0);
	}


	gl_FragColor.rgb += 
		0.005 * 
			(
				leftColor.rgb * (dot(vec2(-1.0, 0.0), vectorTexel.rb) * 8.0) + 
				rightColor.rgb * (dot(vec2(1.0, 0.0), vectorTexel.rb) * 8.0) + 
				downColor.rgb * (dot(vec2(0.0, -1.0), vectorTexel.rb) * 8.0) + 
				upColor.rgb * (dot(vec2(0.0, 1.0), vectorTexel.rb) * 8.0) - 
				2.0 * gl_FragColor.rgb
			);
}