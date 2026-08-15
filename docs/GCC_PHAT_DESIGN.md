# Clean-room GCC-PHAT delay-estimation design

## Scope and provenance

Generalized cross-correlation with phase-transform weighting (GCC-PHAT) is
the second time-difference-of-arrival estimator planned for this project.
It provides a classical microphone-to-microphone comparison with the LMS
path; it is not an artificial-intelligence method or a production acoustic
localizer.

The implementation is derived independently from the mathematical
definition below and the cited publication by Knapp and Carter. It uses
ordinary MATLAB FFT operations and must not call the Phased Array System
Toolbox `gccphat` function. No historical project source is used as an
implementation specification.

## Signal and delay convention

Let `x[n]` be the signal whose delay is being estimated and let `y[n]` be
the reference signal. The returned delay is positive when `x` arrives later
than `y`:

```text
x[n] = y[n - D]  ->  estimated delay = +D samples
```

A negative result means that `x` leads the reference. This convention
matches the project's TDOA definition:

```text
TDOA_i,r = arrival_i - arrival_r.
```

## GCC-PHAT definition

For discrete Fourier transforms `X[k]` and `Y[k]`, the cross-power spectrum
for the stated sign convention is

```text
G_xy[k] = X[k] conj(Y[k]).
```

PHAT retains the cross-spectrum phase while normalizing its magnitude:

```text
Psi_PHAT[k] = G_xy[k] / max(|G_xy[k]|, epsilon).
```

The small positive `epsilon` prevents division by zero. A zero-energy input
pair cannot provide a delay estimate and is rejected explicitly rather than
reported as a successful zero delay.

The generalized cross-correlation is the inverse transform

```text
r_PHAT[l] = IFFT{Psi_PHAT[k]}.
```

The implementation zero-pads to at least the full linear-correlation length
before taking the FFT, shifts the circular IFFT output onto an explicit
signed-lag axis, and searches only physically or mathematically admissible
lags. The initial integer estimate is the lag at the largest correlation
magnitude. Returned diagnostics retain the searched lag vector, correlation
values, selected peak, FFT length, and normalization threshold.

## Physical lag constraint

For microphones separated by `d` metres, propagation speed `c` metres per
second, and sample rate `f_s` hertz, a direct-path plane or point source
cannot produce a larger absolute TDOA than

```text
|TDOA| <= d / c seconds
|delay| <= d f_s / c samples.
```

The discrete search limit uses the ceiling of the sample bound so a valid
fractional delay near the boundary is not discarded. It is also capped by
the finite-signal linear-correlation range. Geometry-derived limits are an
explicit input to the estimator; the estimator does not assume microphone
coordinates or silently invent a bound.

## Sub-sample interpolation

After selecting an interior integer peak, a three-point quadratic fit to
the neighboring correlation magnitudes estimates a local fractional
offset. With adjacent magnitudes `a`, `b`, and `c`, centered on the peak,

```text
delta = 0.5 (a - c) / (a - 2b + c).
```

The interpolated estimate is `integerLag + delta`. Interpolation is skipped
and reported in diagnostics when the peak is at the search boundary, the
curvature denominator is numerically unsafe, or the fitted stationary point
is not a valid local offset. The integer peak remains available separately.

Quadratic peak interpolation is a local numerical approximation, not a
claim that GCC-PHAT is universally accurate below one sample.

## Numerical limitations

- PHAT discards magnitude information and can emphasize unreliable phase in
  low-energy frequency bins; epsilon protection limits but does not remove
  this sensitivity.
- Finite observation windows, spectral leakage, narrowband or periodic
  signals, and multiple similar peaks can make the estimate ambiguous.
- Additive noise, reflections, reverberation, clock mismatch, and microphone
  responses can broaden or move the peak. Only additive noise is modeled in
  the current direct-path simulation.
- The geometry bound assumes known microphone coordinates and sound speed.
- Peak height is not a calibrated confidence probability.
- Tests use deterministic broadband signals and explicitly justified
  tolerances; their performance is not a general real-world accuracy claim.

## Primary reference

C. H. Knapp and G. C. Carter, "The Generalized Correlation Method for
Estimation of Time Delay," *IEEE Transactions on Acoustics, Speech, and
Signal Processing*, vol. 24, no. 4, pp. 320-327, August 1976.
[DOI: 10.1109/TASSP.1976.1162830](https://doi.org/10.1109/TASSP.1976.1162830).

The publication is a mathematical and conceptual reference only. No source
code from it, MathWorks, or the excluded historical repository is included.
