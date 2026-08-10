# Clean-room LMS adaptive-filter design

## Scope

This project uses the standard real-valued least-mean-squares (LMS)
adaptive FIR filter for deterministic simulation and system-identification
experiments. The implementation is written independently from the
mathematical definition below. It does not copy, translate, or reconstruct
the historical project's `lms.m`, `convm.m`, comments, control flow, or
data structures.

LMS is used here as a classical adaptive signal-processing algorithm. It is
not presented as machine learning, a production acoustic estimator, or a
real-time hardware implementation.

## Signal and coefficient convention

Let `x[n]` be the input signal, `d[n]` the desired signal, and `L` the FIR
filter length. At sample `n`, the causal rolling input vector is

```text
x_n = [x[n], x[n-1], ..., x[n-L+1]]^T,
```

where samples before the start of the supplied signal are zero. The
coefficient vector uses the same newest-to-oldest ordering:

```text
w_n = [w_0[n], w_1[n], ..., w_(L-1)[n]]^T.
```

Consequently, coefficient `w_k` multiplies an input delayed by `k` samples.
This convention makes the index of an identified impulse-response peak an
explicit nonnegative causal delay.

## Update equations

For each supplied sample, the output and a-priori error are calculated from
the coefficients that exist before the current update:

```text
y[n] = w_n^T x_n
e[n] = d[n] - y[n]
```

The coefficients are then updated once:

```text
w_(n+1) = w_n + mu e[n] x_n,
```

where `mu` is a positive scalar step size. The implementation performs this
sample-by-sample recursion directly with a rolling vector; it does not build
a convolution matrix.

The returned output and error sequences therefore describe the pre-update
filter at each sample, while final coefficients describe the state after
the last update. If coefficient history is requested later, its first row
will be the initial coefficients and row `n+1` will be the state after
processing sample `n`.

## Step size and convergence

A positive step size is necessary but does not by itself guarantee
convergence. Classical mean-convergence analysis relates the useful range
to the eigenvalues of the input autocorrelation matrix; a commonly stated
condition under the analysis assumptions is

```text
0 < mu < 2 / lambda_max.
```

The implementation cannot infer a universal safe step size from arbitrary
finite input data. Callers are responsible for choosing `mu`, and tests use
deterministic persistently exciting inputs with conservative values.
Correlated inputs, insufficient excitation, observation noise, excessive
step size, finite data, and finite precision can slow convergence or leave
steady-state coefficient error.

## Initial implementation boundary

Day 8 implements ordinary LMS for equal-length, finite, real-valued signal
vectors. It validates the filter length, step size, signal dimensions,
sample count, and optional initial coefficients. Signed microphone delays,
bulk alignment, impulse-response and phase-slope delay estimators, and their
additional diagnostics belong to Day 9.

## References

1. B. Widrow and M. E. Hoff, Jr., “Adaptive Switching Circuits,” *IRE
   WESCON Convention Record*, part 4, pp. 96–104, August 1960.
   [Author-hosted paper](https://isl.stanford.edu/~widrow/papers/c1960adaptiveswitching.pdf)
   and [Stanford publication record](https://isl.stanford.edu/~widrow/publications.html).
2. A. H. Sayed, *Adaptive Filters*. Wiley-IEEE Press, 2008, especially the
   LMS algorithm and performance chapters. ISBN 978-0-470-25388-5,
   [DOI: 10.1002/9780470374122](https://doi.org/10.1002/9780470374122).

These publications are conceptual and mathematical references only; no
source code from them or from the historical project is included.
