# Fractional-Delay Design Decision

## Decision

V0.1 uses an independently implemented, windowed-sinc finite impulse response (FIR) interpolator for nonnegative fractional delays. This method keeps the delay operation explicit, deterministic, and testable without relying on a toolbox fractional-delay object.

The implementation follows the standard ideal fractional-delay response described conceptually by Laakso et al. [1]. The code and its structure are original to this repository and are not derived from the historical `lms.m`, `convm.m`, or any historical helper implementation.

## Delay decomposition

A requested delay in samples is decomposed as

```text
D = K + mu
```

where `K = floor(D)` is a nonnegative integer delay and `0 <= mu < 1` is the fractional part. Exact integer delays, including zero, bypass interpolation and use `micloc.applyIntegerDelay` so their samples and output lengths remain exact.

## FIR response

The default interpolator has 65 taps. Its odd length places the zero-fraction reference response at the central tap and gives a causal FIR group delay of

```text
M = (65 - 1) / 2 = 32 samples
```

For integer tap coordinate `m = -M, ..., M`, the unnormalized impulse response is

```text
h[m] = sinc(m - mu) * w[m]
```

where normalized `sinc(x) = sin(pi*x)/(pi*x)`, with `sinc(0) = 1`. The symmetric Hann window is

```text
w[n] = 0.5 - 0.5*cos(2*pi*n/(L - 1)),  n = 0, ..., L - 1
```

The coefficients are normalized to unit DC gain. The Hann window was selected as a simple, reproducible compromise between transition width and truncation sidelobes. The filter length is configurable as an odd integer of at least three taps, while 65 taps is the documented and tested default.

## Group-delay compensation and alignment

Direct convolution with the causal 65-tap FIR introduces the fixed 32-sample group delay in addition to `mu`. The implementation compensates that fixed delay explicitly by discarding the first 32 convolution samples from the aligned result.

For a noninteger delay, one additional output sample is retained to represent the delayed end of the finite input. The integer portion `K` is then applied as leading-zero padding. Consequently:

```text
output length = input length + ceil(D)
```

For an exact integer delay, this reduces to the integer-delay policy already documented. All microphone channels are later padded to a shared length based on the largest requested delay. The fractional-delay function accepts row or column vectors, preserves their orientation, and returns double-precision samples.

## Boundary behaviour

Samples outside the supplied finite signal are assumed to be zero. Windowed-sinc interpolation can therefore produce boundary transients and small pre/post-ringing near the beginning and end of a signal. Tests that estimate delay from broadband content must exclude or otherwise account for those boundary regions.

The operation models delay only. It does not apply geometric attenuation, anti-alias resampling, room response, microphone response, or clock-rate conversion.

## Numerical limitations

- A finite FIR approximates the ideal infinite sinc response, so magnitude and phase errors increase near Nyquist.
- Shorter configured filters reduce computation but worsen the approximation.
- Delay estimates depend on signal bandwidth, estimator choice, boundary exclusion, and numerical tolerance.
- The initial approximately 0.10-sample validation target applies only to the documented broadband test band and is not a universal accuracy guarantee.
- Only nonnegative causal propagation delays are supported at this simulation stage. Signed relative lags are handled explicitly in later TDOA-estimation work.
- Very short signals can be dominated by boundary effects even when the requested delay is mathematically valid.

Diagnostics must report the requested delay, integer and fractional components, filter length, compensated group delay, and output length. Solver or estimator stages must not silently reinterpret these values.

## Reference

[1] T. I. Laakso, V. Valimaki, M. Karjalainen, and U. K. Laine, “Splitting the unit delay—Tools for fractional delay filter design,” *IEEE Signal Processing Magazine*, vol. 13, no. 1, pp. 30–60, 1996. DOI: `10.1109/79.482137`.
