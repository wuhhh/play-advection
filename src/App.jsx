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
import smokeConfig from "./inc/smokeConfig";

const colorMaterial = shaderMaterial(
  {
    uSmokeDistance: 0.0,
    uDiffuseMult1: 0.0,
    uDiffuseMult2: 0.0,
    uDiffuseDownMult: 0.0,
    uDiffuseUpMult: 0.0,
    uRes: null,
    uSmokeSource: null,
    uTexture: null,
    uVelocityTexture: null,
    uTime: 0,
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
  const graphicTexture = useTexture("/water-normal.jpg");
  // const graphicTexture = useTexture("/water-detail.jpg");
  const bufferMaterial = useRef();

  // Controls
  const smokeControls = useControls("smoke", smokeConfig, { collapsed: true });

  // Create buffer scene
  const bufferScene = useMemo(() => new THREE.Scene(), []);

  // Default camera
  const camera = useThree(state => state.camera);

  // Viewport size
  const { width, height } = useThree(state => state.viewport);

  // Create 2 buffer textures
  let textureA = useFBO();
  let textureB = useFBO();

  // Set material and pass uniforms
  bufferMaterial.current = new colorMaterial({
    uSmokeDistance: smokeControls.uSmokeDistance,
    uDiffuseMult1: smokeControls.uDiffuseMult1,
    uDiffuseMult2: smokeControls.uDiffuseMult2,
    uDiffuseDownMult: smokeControls.uDiffuseDownMult,
    uDiffuseUpMult: smokeControls.uDiffuseUpMult,
    uRes: new THREE.Vector2(window.innerWidth, window.innerHeight),
    uSmokeSource: new THREE.Vector3(0, 0, 0),
    uTexture: textureA.texture,
    uVelocityTexture: graphicTexture,
    uTime: 0,
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
      <Leva hidden />
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
      <Canvas linear flat camera={{ fov: 75, position: [0, 0, 2.5] }}>
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
