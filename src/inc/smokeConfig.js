const config = {
  uSmokeDistance: {
    value: 15.0,
    min: 0.0,
    max: 30.0,
    step: 0.1,
  },
  uDiffuseMult1: {
    value: 8.0,
    min: 0.0,
    max: 12.0,
    step: 0.1,
  },
  // This is 1/60 fps
  uDiffuseMult2: {
    value: 0.016,
    min: 0.0,
    max: 0.1,
    step: 0.001,
  },
  uDiffuseDownMult: {
    value: 3.0,
    min: 0.0,
    max: 6.0,
    step: 0.1,
  },
  uDiffuseUpMult: {
    value: 6.0,
    min: 0.0,
    max: 12.0,
    step: 0.1,
  },
};

export default config;
