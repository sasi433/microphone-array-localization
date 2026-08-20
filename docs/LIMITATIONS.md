# V1.0 limitations, non-claims, and future work

## Simulation boundary

V1.0 is a deterministic MATLAB study of one stationary synthetic source in
a two-dimensional, synchronized, direct-path, free-field model. It is not:

- an artificial-intelligence or machine-learning system;
- a production or safety-critical acoustic-localization product;
- a real-time audio system;
- a complete room-acoustics simulator;
- a multiple-source separator, tracker, or three-dimensional estimator;
- evidence of performance on physical microphones or real recordings.

## Acoustic omissions

The simulation omits reflections, reverberation, diffraction, obstacles,
air absorption, distance-dependent amplitude loss, microphone directivity
and frequency response, analogue electronics, automatic gain control,
quantization, clipping, and environmental variation in sound speed. These
effects can change or obscure the learned transfer response and invalidate
the single-delay phase model.

## Synchronization and calibration

All channels share one ideal sample clock. V1.0 does not model clock offset,
clock drift, dropped samples, device latency, microphone position error, or
calibration uncertainty. Real distributed devices require synchronization
and calibration that this project does not provide.

## Geometry

A linear array cannot distinguish mirror sources on opposite sides of its
axis from TDOAs alone. V1.0 exposes this ambiguity and supports a half-plane
constraint; it does not make the geometry informative. Poor aperture,
distant sources, nearly collinear non-linear layouts, or inaccurate bounds
can make localization ill-conditioned even when TDOA errors are small.

## Delay simulation

Integer mode quantizes absolute propagation delays and can create meaningful
coordinate error. Fractional mode uses a finite Hann-windowed sinc FIR, so
it approximates rather than exactly realizes an ideal broadband delay.
Boundary transients and zero padding are part of the simulated signals.

## LMS limitations

LMS convergence depends on excitation bandwidth, correlation, signal power,
step size, filter length, observation duration, and noise. A positive step
size is not a universal stability guarantee. Too little bulk delay cannot
represent negative TDOAs; too short a filter cannot represent large causal
lags; unnecessarily large values increase cost and can slow convergence.

The current pipeline adapts every non-reference microphone independently
against the reference. It does not jointly enforce pairwise consistency,
adapt online to moving sources, or automatically tune LMS settings.

## Delay-estimator limitations

The impulse-response peak estimator has one-sample resolution and can become
ambiguous when neighboring or multipath peaks are comparable. Phase slope
requires sufficient magnitude and approximately linear unwrapped phase over
the selected band. Its R-squared and residual diagnostics reveal but do not
repair a poor model fit. Phase wrapping, narrowband excitation, noise,
spectral notches, and multi-path transfer functions can bias the result.

GCC-PHAT discards cross-spectrum magnitude information and can emphasize
unreliable phase in low-energy bins. Finite windows, narrowband or periodic
signals, additive noise, and similar correlation peaks can bias or make the
estimate ambiguous. Geometry-derived lag limits reject physically impossible
peaks but do not resolve corrupted or uninformative data. Three-point
quadratic peak interpolation is a local numerical approximation rather than
a general sub-sample accuracy guarantee.

## Optimization and reported accuracy

`lsqnonlin` is local and depends on the initial guess, bounds, geometry, and
TDOA estimates. A positive exit flag does not prove that the physical source
was uniquely or globally recovered. V1.0 reports solver state, residual norm,
and localization error for known simulated coordinates; it does not provide
uncertainty intervals or guarantees for unknown real sources.

The selected V0.1 example is one deterministic, well-conditioned clean scene.
Its millimetre-scale result is not a general performance claim. V1.0's
repeated seeded SNR experiments broaden the synthetic evaluation, but they
still use the same synchronized direct-path assumptions. Reverberant data and
real hardware evaluation remain outside the implemented scope.

## Experiment limitations

Monte Carlo and SNR summaries describe only the configured synthetic scenes,
signals, seeds, trial counts, and estimator settings. They are not confidence
intervals, population estimates, benchmarks against measured data, or
certification of accuracy. A small trial count can make means, extrema, and
percentiles unstable. Solver failures are counted explicitly and are not
silently replaced with finite localization errors.

Comparisons are controlled by providing identical simulated microphone
signals to each estimator. That removes one source of random variation but
does not make estimator assumptions equivalent or establish universal method
rankings. Results can change with bandwidth, duration, sample rate, array
geometry, source location, SNR, and parameter choices.

## Future work, not V1.0 scope

The following are reasonable research extensions, but none is implemented or
claimed by this release:

- **Real recordings:** introduce licensed, documented recordings and a
  repeatable acquisition/evaluation protocol.
- **Room reverberation:** model or measure room impulse responses, reflections,
  multipath, and frequency-dependent absorption.
- **Multiple sources:** add source separation, delay association, and an
  estimator designed for simultaneous emitters.
- **Tracking:** add a time-varying state model, frame-level observations, and
  explicit missed-detection and data-association handling.
- **Three-dimensional arrays:** extend geometry, observability checks,
  coordinate solving, plots, and tests to non-coplanar microphone layouts.
- **Hardware synchronization:** measure and compensate device latency, sample
  loss, clock offset, and drift.
- **Calibration:** estimate microphone positions, gains, responses, and sound
  speed rather than treating them as exactly known.

Each extension changes the mathematical assumptions and validation evidence.
It should be developed as separately reviewed scope with suitable data
provenance, tests, and dependency analysis rather than appended to V1.0.

## Intended interpretation

Use V1.0 to inspect and reproduce a modular academic signal-processing
pipeline. Do not extrapolate its clean synthetic results to rooms, devices,
people, safety decisions, surveillance, or commercial performance.
