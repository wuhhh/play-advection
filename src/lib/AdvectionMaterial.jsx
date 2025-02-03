import { shaderMaterial } from "@react-three/drei";
import smokeShader from "./shaders/advect.glsl";

const advectionMaterial = shaderMaterial(
  {
    uAdvDist: null,
    uBaseColor: null,
    uColorMode: null,
    uFactor: null,
    uMouseVelocity: 0,
    uRGBIntensity: null,
    uRGBRadius: null,
    uRGBThroughput: null,
    uAdvectedMix: 0.5,
    uRes: null,
    uSmokeSource: null,
    uTexture: null,
    uTime: 0,
    uVelocityTexture: null,
  },
  /* glsl */ `
		varying vec2 vUv;
		void main() {
			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
		}
	`,
  smokeShader
);

export default advectionMaterial;
