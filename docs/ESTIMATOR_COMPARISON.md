# LMS versus GCC-PHAT comparison

## Purpose and scope

The project supports three time-difference-of-arrival (TDOA) estimators:

- `lms-peak`: the integer location of the learned LMS FIR peak;
- `lms-phase`: the delay inferred from the learned FIR's unwrapped phase
  slope; and
- `gcc-phat`: generalized cross-correlation with phase-transform weighting,
  a geometry-constrained peak search, and local quadratic interpolation.

LMS preserves the historical academic signal-processing direction of this
clean-room reconstruction. GCC-PHAT supplies a modern classical
microphone-to-microphone TDOA comparison. Neither method is presented as
artificial intelligence, a production localization system, or a universal
winner.

## Fair comparison contract

`micloc.compareTDOAEstimators` changes only `config.tdoaEstimator`. Every
method receives the same validated geometry, source position, sample rate,
source settings, propagation method, noise setting, SNR, seed, and solver
configuration. The function verifies exact equality of all four signal
artifacts before reporting a comparison:

1. generated source samples;
2. clean microphone channels;
3. noisy microphone channels; and
4. added noise samples.

If any artifact differs, the comparison raises an error instead of
presenting unequal inputs as a fair experiment. Metrics exclude the
reference microphone's fixed zero TDOA and report mean absolute, RMS, and
maximum absolute delay errors in samples. Complete method results remain
available so solver failures and localization errors are visible.

## Reproducible use

Run one identical-input comparison:

```matlab
setupProject;
config = micloc.modernDemoConfig();
comparison = micloc.compareTDOAEstimators(config);
disp(comparison.delayMetricsTable);
```

Select one estimator for an ordinary end-to-end simulation:

```matlab
config.tdoaEstimator = 'gcc-phat'; % lms-peak | lms-phase | gcc-phat
result = micloc.runLocalizationSimulation(config);
```

Run repeated seeded localization comparisons across SNR:

```matlab
snrLevelsDb = [Inf, 40, 30, 20, 10, 5, 0];
experiment = micloc.runEstimatorSNRComparison( ...
    config, snrLevelsDb, 10, 20000);
disp(experiment.summaryTable);
```

Each SNR trial uses one consecutive seed and one shared signal realization
for all three estimators. `trialTable` preserves per-method solver status,
localization error, and delay errors. `summaryTable` reports localization
statistics and solver-failure counts separately for every estimator and SNR.
Generated tables should normally be written below the ignored `results/`
directory; selected documentation results require their exact configuration
and seeds.

## Algorithmic differences

| Property | LMS peak | LMS phase | GCC-PHAT |
| --- | --- | --- | --- |
| Input to delay stage | Learned pairwise FIR | Learned pairwise FIR | Microphone-signal pair |
| Primary operation | Largest FIR coefficient | Unwrapped phase regression | PHAT-weighted cross-correlation peak |
| Initial lag grid | Causal FIR coefficients | Frequency-bin phase slope | Signed correlation lags |
| Fractional estimate | No | Yes | Three-point quadratic interpolation |
| Signed-delay mechanism | Configured causal bulk delay | Configured causal bulk delay | Native signed lag axis |
| Physical lag constraint | FIR length and bulk delay | FIR length and bulk delay | Microphone separation and sound speed |

The methods therefore do not have identical tuning parameters. Fairness here
means identical observed signals and transparent method-specific settings,
not pretending that their internal computations are interchangeable.

## Interpretation limits

Results depend on microphone geometry, source position, signal duration and
bandwidth, sample rate, SNR, random realization, propagation approximation,
sound speed, LMS convergence settings, lag bounds, interpolation bias, and
coordinate-solver behavior. A ranking from one seed or one SNR is not a
general accuracy claim.

The current simulator is synchronized, single-source, two-dimensional, and
direct-path. It does not model room reflections, reverberation, microphone
responses, calibration error, hardware clock mismatch, motion, or competing
sources. PHAT can emphasize unreliable low-energy phase; LMS can fail to
converge or learn a clean delay response. Quadratic interpolation is a local
approximation. Geometry constraints can reject impossible peaks but cannot
make ambiguous or corrupted data informative.

Solver success, estimator diagnostics, valid-trial counts, and failure counts
must be interpreted alongside localization-error summaries. Neither LMS nor
GCC-PHAT should be described as production-ready based on these synthetic
experiments.

## Design references

- [`LMS_DESIGN.md`](LMS_DESIGN.md) defines the independently implemented LMS
  update and coefficient ordering.
- [`LMS_DELAY_ESTIMATION.md`](LMS_DELAY_ESTIMATION.md) defines bulk-delay,
  peak, phase-slope, and sign conventions.
- [`GCC_PHAT_DESIGN.md`](GCC_PHAT_DESIGN.md) defines GCC-PHAT normalization,
  signed lags, physical bounds, interpolation, and numerical limitations.
- [`PROVENANCE.md`](PROVENANCE.md) defines the clean-room boundary.
