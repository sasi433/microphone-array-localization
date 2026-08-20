# V1.0 direct-path simulation assumptions

## Intended model

V1.0 is a deterministic, single-source, two-dimensional signal-processing simulation. It creates a synthetic source waveform, calculates ideal geometric propagation delays to synchronized microphones, applies those delays, and optionally adds independent Gaussian noise at a measured target SNR.

The current model is suitable for testing the mathematical stages of a clean-room academic localization pipeline. It is not a complete acoustic environment, a real-time system, or a production localization product.

## Direct-path propagation

Each microphone receives one delayed copy of the source. Propagation time is calculated as Euclidean source-to-microphone distance divided by a known, constant speed of sound. Integer-delay mode quantizes propagation to whole samples and applies causal leading-zero padding without discarding input samples.

Microphone channels share a common output length. Shorter-delay channels receive trailing zeros so that every matrix row represents the same simulation time index. Fractional-delay alignment and its finite-filter assumptions are documented in [Fractional-Delay Design](FRACTIONAL_DELAY_DESIGN.md).

The geometric and TDOA sign conventions are defined in [Array Geometry and Propagation Conventions](GEOMETRY.md).

## Additive noise

Optional noise is synthetic, independent Gaussian noise generated from a documented seed without changing MATLAB's global random state. For a finite requested SNR, noise is scaled from the measured mean-square clean power of each channel. This makes SNR a controlled numerical experiment setting rather than a claim about a physical microphone or room.

Positive-infinite SNR means no added noise. A finite SNR is undefined for a zero-power clean channel and is reported as an error rather than silently fabricated.

## Explicit exclusions

V1.0 does not model:

- Room reflections or multipath propagation
- Reverberation or frequency-dependent wall absorption
- Air absorption, spreading loss, or distance-dependent amplitude attenuation
- Microphone frequency response, directivity, self-noise, gain mismatch, or calibration error
- Source or microphone motion
- Hardware synchronization error between microphones
- Sampling-clock offset or clock drift
- Sample loss, quantization, clipping, or analogue-to-digital converter behaviour
- Multiple simultaneous sound sources
- Diffuse, correlated, directional, or nonstationary environmental noise
- Real-time processing or bounded processing latency
- Real microphone, sound-card, or recording input
- Three-dimensional propagation or localization

These effects can materially change delay estimation and localization accuracy. Results from the direct-path simulation must not be presented as measured real-world performance.

## Reproducibility boundary

Documented configurations, seeds, MATLAB release, and toolbox versions are part of a reproducible experiment. Deterministic generation ensures that a repeated configuration produces the same synthetic inputs. It does not remove numerical sensitivity, geometry ambiguity, estimator bias, or solver failure.

Generated experiment output normally remains untracked under `results/`. Only deliberately selected results with their exact configuration and seed should be committed for documentation.

Repeated trials and estimator comparisons remain synthetic experiments under
these same assumptions. Increasing the number of seeds or SNR levels does not
introduce room, device, calibration, or recording realism.
