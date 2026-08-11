# LMS delay-estimation conventions and limitations

## Scope

This note defines how the clean-room LMS filter is used to estimate relative
arrival delays between two simulated microphone channels. It builds on the
independent LMS equations and coefficient ordering in
[`LMS_DESIGN.md`](LMS_DESIGN.md). Day 9 estimates pairwise delay only; source
coordinates are still estimated separately from a complete TDOA vector.

## Signed microphone TDOA

For a reference microphone `r` and comparison microphone `i`, the convention
is

```text
TDOA_i,r = arrival_i - arrival_r.
```

A positive TDOA means the comparison microphone receives the signal later.
A negative TDOA means it receives the signal earlier. Convert samples to
seconds only after estimation:

```text
TDOA_seconds = TDOA_samples / sampleRateHz.
```

The reference microphone's TDOA remains exactly zero.

## Causal bulk-delay alignment

A causal FIR filter cannot directly represent a negative lag. For an
equal-length pair, `alignMicrophonePairForLMS` therefore uses the reference
channel as the adaptive input, appends `B` trailing zeros, and prepends `B`
zeros to the comparison channel to form the desired signal. No original
samples are discarded.

If the signed microphone TDOA is `Delta` samples, the causal adaptive-filter
lag is

```text
K = B + Delta.
```

After estimation, both delay methods apply

```text
Delta = K - B.
```

The bulk delay must be at least the magnitude of the most negative TDOA that
must be represented. The adaptive-filter length must exceed the largest
expected causal lag `B + Delta`; otherwise the required peak lies outside
the coefficient vector. Excessive bulk delay wastes coefficients and slows
adaptation, so it should be based on the array's physical maximum TDOA.

## Impulse-response peak method

`estimateDelayFromImpulseResponse` finds the unique largest absolute LMS
coefficient. With the package's zero-delay-first ordering,

```text
K = peakCoefficientIndex - 1.
```

The method has one-sample resolution and performs no sub-sample
interpolation. A fractional physical delay will normally select a nearby
integer coefficient. Diagnostics report the largest and second-largest
magnitudes and their ratio. An all-zero response or exactly tied largest
peaks is rejected because neither identifies a unique delay.

Peak estimation is simple and easy to inspect, but it becomes unreliable
when adaptation spreads energy over neighboring taps, the input lacks
bandwidth, noise creates competing peaks, or the true transfer path is not
well approximated by one dominant delay.

## Unwrapped phase-slope method

For a pure causal delay `D` samples, the frequency response has approximately
linear phase

```text
phase(omega) = intercept - D * omega.
```

`estimateDelayFromPhase` calculates the FIR frequency response, selects an
explicit frequency band, rejects bins below a relative magnitude threshold,
unwraps the remaining phase, and performs linear least-squares regression.
The raw delay is the negative fitted slope in samples.

If the supplied coefficients contain a known fixed group delay `G`, the
conversion is

```text
K = rawDelay - G
Delta = K - B.
```

The project's fractional-delay signal generator already compensates its
windowed-sinc group delay in the aligned output. Therefore LMS coefficients
learned from those aligned microphone signals normally use `G = 0`; passing
the interpolation filter's group delay again would double-compensate it.
The explicit parameter remains available for independently supplied FIR
coefficients that genuinely include a known fixed group delay.

Diagnostics include the selected frequencies, phase residuals, root-mean-
squared phase error, and coefficient of determination. Fits with R-squared
below 0.95 are labeled `poor` rather than reported without qualification.
Too few valid bins and an all-zero response are identified failures.

## Numerical and modelling limitations

The deterministic clean tests use broadband Gaussian excitation because LMS
system identification requires adequate excitation. Results can degrade or
fail because of:

- an unstable or poorly chosen LMS step size;
- too few adaptation samples or an adaptive filter that is too short;
- narrowband or strongly correlated input signals;
- observation noise and steady-state LMS misadjustment;
- low-magnitude frequency bins, phase wrapping, or a poorly chosen fit band;
- multiple comparable impulse-response peaks;
- reflections, reverberation, dispersion, or microphone responses that are
  not described by one direct-path delay;
- an incorrect bulk-delay bound or inconsistent reference/comparison order;
- finite sampling resolution and fractional-delay approximation error.

The current simulation assumes synchronized channels, a single source, and
a direct path. A good clean phase fit is evidence that the learned FIR is
approximately delay-like over the selected band; it is not proof of robust
performance on real recordings.

## Reproducible clean-test settings

The Day 9 tests use 48 kHz sampling, deterministic seeded Gaussian signals,
a bulk delay of eight samples, a 25-tap LMS filter, step size 0.003, and a
1–18 kHz phase-fit band. These values are test fixtures, not universal
defaults. The tests require exact or near-exact integer recovery, allow the
discrete peak method its expected half-sample rounding error on fractional
cases, and require the phase method to remain within 0.02 sample in the
selected clean cases.
