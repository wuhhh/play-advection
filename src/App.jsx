/**
 * Based on https://code.tutsplus.com/how-to-write-a-smoke-shader--cms-25587t
 * Ported to React Three Fiber by Huw Roberts (huwroberts.net)
 */

import * as THREE from "three";
import React, { useEffect, useMemo, useRef, useState } from "react";
import { Canvas, extend, useFrame, useThree } from "@react-three/fiber";
import { shaderMaterial, useFBO, useTexture } from "@react-three/drei";
import { Leva, useControls } from "leva";

import smokeShader from "./shaders/smoke.glsl";

const colorMaterial = shaderMaterial(
  {
    uAdvDist: null,
    uBaseColor: null,
    uColorMode: null,
    uFactor: null,
    uRGBIntensity: null,
    uRGBRadius: null,
    uRGBThroughput: null,
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

extend({ ColorMaterial: colorMaterial });

const FBOScene = ({ ...props }) => {
  // const graphicTexture = useTexture("/rgbnorm1.png"); // Norm swirl
  const graphicTexture = useTexture("/holo.jpg");
  // const graphicTexture = useTexture("/img1.jpg"); // Abstract graphic
  // const graphicTexture = useTexture("/water-normal.jpg"); // Water
  // const graphicTexture = useTexture("/11092-normal.jpg"); // Scaly
  // const graphicTexture = useTexture("/11013-normal.jpg"); // Abstract
  // const graphicTexture = useTexture("/5952-normal.jpg"); // Cracked smoke
  // const graphicTexture = useTexture("/1073-normal.jpg"); // Fine smoke
  const bufferMaterial = useRef();

  const config = useControls("Smoke", {
    advectionDistance: {
      value: 1.0,
      min: 1.0,
      max: 10.0,
      step: 0.1,
    },
    baseTextureColor: {
      value: "#2e6b75",
    },
    colorMode: {
      value: "Additive",
      options: ["Additive", "Subtractive"],
    },
    factor: {
      value: 6,
      min: 1,
      max: 20,
      step: 1,
    },
    rgbIntensity: {
      value: {
        x: 5.0,
        y: 2.0,
        z: 1.0,
      },
      min: 1.0,
      max: 100.0,
      step: 1.0,
    },
    rgbRadius: {
      value: {
        x: 120.0, // r
        y: 75.0, // g
        z: 120.0, // b
      },
      min: 0.0,
      max: 150.0,
      step: 1.0,
    },
    rgbThroughput: {
      value: {
        x: 6.0,
        y: 3.0,
        z: 3.0,
      },
      min: 1.0,
      max: 100.0,
      step: 1.0,
    },
  });

  // Base texture
  // You could use this for a non-uniform base texture
  // But when it's a solid, it's better to use a uniform
  /* const baseTextureSize = 4;
  const baseTextureValues = new Float32Array(4 * baseTextureSize * baseTextureSize);
  for (let i = 0; i < baseTextureSize; i++) {
    for (let j = 0; j < baseTextureSize; j++) {
      const index = i * baseTextureSize + j;
      baseTextureValues[4 * index] = config.baseTextureColor.r;
      baseTextureValues[4 * index + 1] = config.baseTextureColor.g;
      baseTextureValues[4 * index + 2] = config.baseTextureColor.b;
      baseTextureValues[4 * index + 3] = 1.0;
    }
  }
  const baseTexture = new THREE.DataTexture(baseTextureValues, baseTextureSize, baseTextureSize, THREE.RGBAFormat, THREE.FloatType);
  baseTexture.needsUpdate = true; */

  // Create buffer scene
  const bufferScene = new THREE.Scene();

  // Default camera
  const camera = useThree(state => state.camera);

  // Viewport size
  const { width, height } = useThree(state => state.viewport);

  // Create 2 buffer textures
  let textureA = useFBO();
  let textureB = useFBO();

  // Set material and pass uniforms
  bufferMaterial.current = new colorMaterial({
    uAdvDist: config.advectionDistance,
    uBaseColor: new THREE.Color(config.baseTextureColor),
    uColorMode: config.colorMode === "Additive" ? 1.0 : -1.0,
    uFactor: config.factor,
    uRGBIntensity: new THREE.Vector3(config.rgbIntensity.x, config.rgbIntensity.y, config.rgbIntensity.z),
    uRGBRadius: new THREE.Vector3(config.rgbRadius.x, config.rgbRadius.y, config.rgbRadius.z),
    uRGBThroughput: new THREE.Vector3(config.rgbThroughput.x, config.rgbThroughput.y, config.rgbThroughput.z),
    uRes: new THREE.Vector2(window.innerWidth, window.innerHeight),
    uSmokeSource: new THREE.Vector3(0, 0, 0),
    uTexture: textureA.texture,
    uTime: 0,
    uVelocityTexture: graphicTexture,
  });

  // Buffer plane scaled to viewport size
  const plane = new THREE.PlaneGeometry(1, 1);
  const bufferObject = new THREE.Mesh(plane, bufferMaterial.current);
  bufferObject.scale.set(width, height, 1);
  bufferScene.add(bufferObject);

  const meshDisplay = useRef();

  useFrame(({ clock, gl }, delta) => {
    gl.setRenderTarget(textureB);
    gl.render(bufferScene, camera);
    gl.setRenderTarget(null);
    const t = textureA;
    textureA = textureB;
    textureB = t;
    meshDisplay.current.material.map = textureB.texture;
    bufferMaterial.current.uniforms.uTexture.value = textureA.texture;
    bufferMaterial.current.uniforms.uTime.value = clock.getElapsedTime();
  });

  const updateMousePosition = (x, y) => {
    const mouseX = x;
    const mouseY = window.innerHeight - y;
    bufferMaterial.current.uniforms.uSmokeSource.value.x = mouseX;
    bufferMaterial.current.uniforms.uSmokeSource.value.y = mouseY;
  };

  useEffect(() => {
    window.addEventListener("mousemove", event => {
      updateMousePosition(event.clientX, event.clientY);
    });

    window.addEventListener("mousedown", event => {
      bufferMaterial.current.uniforms.uSmokeSource.value.z = 0.1;
    });

    window.addEventListener("mouseup", event => {
      bufferMaterial.current.uniforms.uSmokeSource.value.z = 0;
    });
  }, []);

  return (
    <>
      {/* <Leva hidden /> */}
      <mesh ref={meshDisplay} scale={[width, height, 1]} position={[0, 0, 0]}>
        <planeGeometry />
        <meshBasicMaterial map={textureB.texture} />
      </mesh>
    </>
  );
};

const App = () => {
  return (
    <>
      <Canvas flat linear camera={{ fov: 75, position: [0, 0, 2.5] }}>
        <FBOScene />
      </Canvas>
      <div
        style={{
          fontFamily: "monospace",
          fontSize: "11px",
          color: "white",
          textTransform: "uppercase",
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          padding: "16px",
          letterSpacing: "1px",
          lineHeight: "1rem",
          pointerEvents: "none",
          userSelect: "none",
        }}
      >
        Draw with your mouse
      </div>
    </>
  );
};

export default App;
