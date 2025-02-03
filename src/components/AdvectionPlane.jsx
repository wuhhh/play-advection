import * as THREE from "three";
import React, { useEffect, useRef, useState } from "react";
import { extend, useFrame, useThree } from "@react-three/fiber";
import { useFBO, useTexture } from "@react-three/drei";
import { useControls } from "leva";
import advectionMaterial from "../lib/AdvectionMaterial";

extend({ AdvectionMaterial: advectionMaterial });

const AdvectionPlane = ({ ...props }) => {
  const graphicTexture = useTexture("/holo-fx.webp");
  const bufferMaterial = useRef();

  const config = useControls("Smoke", {
    advectionDistance: {
      value: 3.0,
      min: 1.0,
      max: 100.0,
      step: 0.1,
    },
    baseTextureColor: {
      value: "#004862",
    },
    colorMode: {
      value: "Additive",
      options: ["Additive", "Subtractive"],
    },
    factor: {
      value: 9,
      min: 1,
      max: 200,
      step: 1,
    },
    rgbIntensity: {
      value: {
        x: 70.0,
        y: 60.0,
        z: 20.0,
      },
      min: 1.0,
      max: 100.0,
      step: 1.0,
    },
    rgbRadius: {
      value: {
        x: 36.0, // r
        y: 68.0, // g
        z: 86.0, // b
      },
      min: 0.0,
      max: 150.0,
      step: 1.0,
    },
    rgbThroughput: {
      value: {
        x: 10.0,
        y: 1.0,
        z: 1.0,
      },
      min: 1.0,
      max: 100.0,
      step: 1.0,
    },
    advectedMix: {
      value: 0.49,
      min: 0.0,
      max: 1.0,
      step: 0.01,
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
  bufferMaterial.current = new advectionMaterial({
    uAdvDist: config.advectionDistance,
    uBaseColor: new THREE.Color(config.baseTextureColor),
    uColorMode: config.colorMode === "Additive" ? 1.0 : -1.0,
    uFactor: config.factor,
    uMouseVelocity: 0,
    uRGBIntensity: new THREE.Vector3(config.rgbIntensity.x, config.rgbIntensity.y, config.rgbIntensity.z),
    uRGBRadius: new THREE.Vector3(config.rgbRadius.x, config.rgbRadius.y, config.rgbRadius.z),
    uRGBThroughput: new THREE.Vector3(config.rgbThroughput.x, config.rgbThroughput.y, config.rgbThroughput.z),
    uAdvectedMix: config.advectedMix,
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
  const mousePosition = useRef(new THREE.Vector2(0, 0));
  const lastMousePosition = useRef(new THREE.Vector2(0, 0));

  const getMouseVelocity = () => {
    // Get the velocity of the mouse
    const dist = mousePosition.current.distanceTo(lastMousePosition.current);
    lastMousePosition.current = { x: mousePosition.current.x, y: mousePosition.current.y };
    return dist * 0.05;
  };

  useFrame(({ clock, gl }) => {
    gl.setRenderTarget(textureB);
    gl.render(bufferScene, camera);
    gl.setRenderTarget(null);
    const t = textureA;
    textureA = textureB;
    textureB = t;
    meshDisplay.current.material.map = textureB.texture;
    bufferMaterial.current.uniforms.uTexture.value = textureA.texture;
    bufferMaterial.current.uniforms.uTime.value = clock.getElapsedTime();

    bufferMaterial.current.uniforms.uMouseVelocity.value = getMouseVelocity();
  });

  const updateMousePosition = (x, y) => {
    const mouseX = x;
    const mouseY = window.innerHeight - y;
    mousePosition.current = new THREE.Vector2(mouseX, mouseY);
    bufferMaterial.current.uniforms.uSmokeSource.value.x = mouseX;
    bufferMaterial.current.uniforms.uSmokeSource.value.y = mouseY;
  };

  useEffect(() => {
    window.addEventListener("mousemove", event => {
      updateMousePosition(event.clientX, event.clientY);
    });
  }, []);

  return (
    <>
      <mesh ref={meshDisplay} scale={[width, height, 1]} position={[0, 0, 0]}>
        <planeGeometry />
        <meshBasicMaterial map={textureB.texture} />
      </mesh>
    </>
  );
};

export default AdvectionPlane;
