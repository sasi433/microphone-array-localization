# References

These publications and official product documents support mathematical
concepts and MATLAB API behaviour. They are references, not source-code
provenance: repository algorithms and tests were written independently under
the clean-room policy in [`PROVENANCE.md`](PROVENANCE.md).

## Adaptive filtering

1. B. Widrow and M. E. Hoff, Jr., "Adaptive Switching Circuits," *IRE
   WESCON Convention Record*, part 4, pp. 96-104, August 1960.
   [Author-hosted paper](https://isl.stanford.edu/~widrow/papers/c1960adaptiveswitching.pdf).
2. A. H. Sayed, *Adaptive Filters*. Wiley-IEEE Press, 2008.
   [DOI: 10.1002/9780470374122](https://doi.org/10.1002/9780470374122).
3. S. Haykin, *Adaptive Filter Theory*, 5th ed. Pearson, 2014.

## Fractional delay and array processing

4. T. I. Laakso, V. Valimaki, M. Karjalainen, and U. K. Laine, "Splitting
   the Unit Delay," *IEEE Signal Processing Magazine*, vol. 13, no. 1,
   pp. 30-60, January 1996.
   [DOI: 10.1109/79.482137](https://doi.org/10.1109/79.482137).
5. M. Brandstein and D. Ward, eds., *Microphone Arrays: Signal Processing
   Techniques and Applications*. Springer, 2001.
   [DOI: 10.1007/978-3-662-04619-7](https://doi.org/10.1007/978-3-662-04619-7).

## Time-delay estimation

6. C. H. Knapp and G. C. Carter, "The Generalized Correlation Method for
   Estimation of Time Delay," *IEEE Transactions on Acoustics, Speech, and
   Signal Processing*, vol. 24, no. 4, pp. 320-327, August 1976.
   [DOI: 10.1109/TASSP.1976.1162830](https://doi.org/10.1109/TASSP.1976.1162830).

## MATLAB product documentation

7. MathWorks, [`lsqnonlin`](https://www.mathworks.com/help/optim/ug/lsqnonlin.html),
   Optimization Toolbox documentation.
8. MathWorks, [`freqz`](https://www.mathworks.com/help/signal/ref/freqz.html),
   Signal Processing Toolbox documentation.
9. MathWorks, [`fft`](https://www.mathworks.com/help/matlab/ref/fft.html),
   MATLAB documentation.
10. MathWorks, [`ifft`](https://www.mathworks.com/help/matlab/ref/ifft.html),
    MATLAB documentation.
11. MathWorks, [`RandStream`](https://www.mathworks.com/help/matlab/ref/randstream.html),
    MATLAB documentation.
12. MathWorks, [MATLAB unit testing framework](https://www.mathworks.com/help/matlab/matlab-unit-test-framework.html).

## How the references are used

| Repository area | Conceptual or API references |
| --- | --- |
| Standard LMS update and convergence context | References 1-3 |
| Windowed-sinc fractional-delay design | Reference 4 |
| Microphone-array and TDOA context | Reference 5 |
| Generalized cross-correlation and PHAT weighting | Reference 6 |
| Vector-valued bounded nonlinear least squares | Reference 7 |
| FIR frequency response and phase processing | Reference 8 |
| FFT-based GCC-PHAT implementation | References 9-10 |
| Deterministic local random streams | Reference 11 |
| Executable verification | Reference 12 |

The mapping identifies concepts and documented interfaces. It does not claim
that publication or MathWorks source code was available, copied, translated,
or adapted.

## Project-specific design records

- [`ARCHITECTURE.md`](ARCHITECTURE.md) defines component boundaries and data
  flow.
- [`LMS_DESIGN.md`](LMS_DESIGN.md) defines coefficient ordering and update
  convention.
- [`LMS_DELAY_ESTIMATION.md`](LMS_DELAY_ESTIMATION.md) defines signed-delay,
  phase-fit, and bulk-delay conventions.
- [`FRACTIONAL_DELAY_DESIGN.md`](FRACTIONAL_DELAY_DESIGN.md) documents the
  windowed-sinc choice and group-delay compensation.
- [`GCC_PHAT_DESIGN.md`](GCC_PHAT_DESIGN.md) defines the GCC-PHAT spectrum,
  sign, lag-bound, epsilon, and interpolation conventions.
- [`ESTIMATOR_COMPARISON.md`](ESTIMATOR_COMPARISON.md) defines the
  identical-signal comparison and interpretation limits.
- [`GEOMETRY.md`](GEOMETRY.md) documents reference microphones and mirror
  ambiguity.
- [`SIMULATION_ASSUMPTIONS.md`](SIMULATION_ASSUMPTIONS.md) records the
  direct-path model.

The uncertain historical helper source attributed to M. H. Hayes is not
distributed, cited as ownership for this implementation, or used as an
implementation specification. Hayes is mentioned in provenance only to
explain why those historical files are excluded.
