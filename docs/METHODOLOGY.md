# V0.1 methodology

## Objective and scope

V0.1 estimates the two-dimensional position of one stationary synthetic
sound source from signals received by synchronized microphones. The model is
direct-path and free-field: propagation is represented by distance-dependent
arrival delay, with optional additive Gaussian noise. The implementation is
a reproducible academic signal-processing simulation, not a real-time or
production acoustic-localization system.

## Processing pipeline

The public entry point is `micloc.runLocalizationSimulation(config)`. Its
deterministic stages are:

1. Validate every configuration field and microphone coordinate.
2. Generate a seeded Gaussian broadband signal or deterministic chirp.
3. Calculate Euclidean source-to-microphone distances and arrival times.
4. Apply integer or group-delay-compensated windowed-sinc fractional delays.
5. Add independently seeded Gaussian noise at a measured per-channel SNR
   when enabled.
6. Align every non-reference channel with the reference by a causal bulk
   delay.
7. Identify each pairwise FIR response with the independently implemented
   standard LMS recursion.
8. Estimate signed TDOA from the learned FIR's unwrapped phase slope.
9. Convert sample delays to seconds and solve the bounded nonlinear
   localization residuals with `lsqnonlin`.
10. Report coordinates, TDOA errors, Euclidean localization error, LMS
    diagnostics, and solver diagnostics.

Each stage is an ordinary MATLAB function under `src/+micloc/` and is tested
independently before end-to-end integration.

## Geometry and propagation

For source position `s` and microphone position `m_i`, distance and arrival
time are

```text
d_i = ||s - m_i||_2
t_i = d_i / c,
```

where `c` is the configured speed of sound in metres per second. Relative
arrival time uses reference microphone `r`:

```text
TDOA_i,r = t_i - t_r.
```

Positive TDOA means microphone `i` receives the signal later. Linear arrays
have a mirror-position ambiguity; a half-plane bound or non-collinear array
is required to select a unique side.

Integer-delay simulation rounds absolute arrival delays to samples.
Fractional mode independently constructs an odd-length Hann-windowed sinc
FIR and compensates its fixed group delay in the output alignment. The
simulation keeps direct-path delay only; it does not model distance
attenuation or room impulse responses.

## LMS system identification

For causal rolling input vector `x_n`, desired sample `d[n]`, coefficients
`w_n`, and step size `mu`, V0.1 uses

```text
y[n] = w_n^T x_n
e[n] = d[n] - y[n]
w_(n+1) = w_n + mu e[n] x_n.
```

Coefficients are ordered from zero delay to `L-1` samples. The reference
channel is the adaptive input. A configured bulk delay `B` is added to the
comparison channel so negative microphone TDOAs can be represented by a
causal FIR. A causal estimate `K` converts back through

```text
TDOA_samples = K - B.
```

The bulk delay and filter length are checked against the simulated TDOA
range. LMS diagnostics expose squared-error history, endpoint-window MSE,
MSE reduction, update count, final coefficients, and optional coefficient
history. Step-size suitability remains signal-dependent.

## Phase-slope delay estimation

For an ideal delay `D` samples, phase is approximately linear in normalized
angular frequency:

```text
phase(omega) = intercept - D * omega.
```

The estimator calculates the learned FIR frequency response, selects a
frequency band, removes low-magnitude bins, unwraps phase, and uses linear
least squares. The negative slope is the raw delay in samples. Known fixed
group delay and the causal bulk delay are then subtracted explicitly.

Diagnostics retain selected bins, residuals, phase-fit RMSE, R-squared, and
a quality label. The impulse-response peak estimator is also available as
an independently tested one-sample-resolution comparison, but the V0.1
pipeline uses phase slope for fractional estimates.

## Coordinate estimation

For candidate source position `p`, predicted TDOAs are calculated from
candidate distances. The residual vector includes every non-reference
microphone:

```text
r_i(p) = predictedTDOA_i(p) - measuredTDOA_i.
```

MATLAB's bounded `lsqnonlin` minimizes the residual vector. Configuration
provides the initial guess, coordinate bounds, iteration and evaluation
limits, and numerical tolerances. The result preserves exit flag, message,
iterations, evaluations, residual norm, first-order optimality, geometry
rank, and mirror-ambiguity diagnostics. Non-convergence is never silently
reported as success.

## Determinism and validation

Source and noise generation use local `RandStream` objects, avoiding changes
to MATLAB's global random state. Tests use fixed seeds and cover geometry,
signals, integer/fractional delays, measured SNR, LMS FIR identification,
signed delay estimation, exact-TDOA localization, clean/noisy end-to-end
localization, invalid inputs, ambiguity, and solver failure reporting.

The verified local command is `matlab -batch "run_tests"`. GitHub Actions
runs the same suite with MATLAB R2026a. V0.1 requires MATLAB, Signal
Processing Toolbox (`freqz`), and Optimization Toolbox (`lsqnonlin`).

## Clean-room boundary

The LMS and delay estimators were written independently from mathematical
definitions and cited publications. Historical `lms.m` and `convm.m` files,
their comments, implementation structure, and Git history are not included,
copied, translated, or reconstructed. See [`PROVENANCE.md`](PROVENANCE.md)
and [`REFERENCES.md`](REFERENCES.md).
