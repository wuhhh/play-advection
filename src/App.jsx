import { Canvas } from "@react-three/fiber";
import { EffectComposer, Grid, Noise, Vignette } from "@react-three/postprocessing";
import { BlendFunction } from "postprocessing";
import { Leva } from "leva";

import AdvectionPlane from "./components/AdvectionPlane";
import OverlayContent from "./components/OverlayContent";

const App = () => {
  return (
    <>
      <Leva hidden />
      <Canvas flat linear camera={{ fov: 75, position: [0, 0, 2.5] }}>
        <AdvectionPlane />
        <EffectComposer>
          <Noise opacity={0.1} blendFunction={BlendFunction.SCREEN} />
          <Grid blendFunction={BlendFunction.OVERLAY} />
          <Vignette eskil={false} offset={0.1} darkness={0.75} />
        </EffectComposer>
      </Canvas>
      <OverlayContent />
    </>
  );
};

export default App;
