# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

No unreleased changes.

## [1.0.0] - 2026-08-20

### Added

- Repeated deterministic localization trials, configurable SNR sweeps,
  summary statistics, CSV export, and error plots
- Independently implemented FFT-based GCC-PHAT with geometry-derived lag
  bounds, epsilon protection, and quadratic sub-sample interpolation
- Identical-signal LMS peak, LMS phase, and GCC-PHAT comparisons across SNR
- Regression coverage for 4, 6, and 8 microphones, arbitrary 2D arrays,
  every non-reference localization residual, degenerate geometry, and solver
  failures
- MATLAB Code Analyzer automation plus JUnit and Cobertura CI artifacts
- V1.0 architecture, methodology, provenance, limitations, selected results,
  citation metadata, and release checklist

### Changed

- End-to-end simulations now select `lms-peak`, `lms-phase`, or `gcc-phat`
  through validated configuration
- Localization diagnostics now include identified measured-TDOA validation,
  normalized termination reasons, and additional residual statistics
- Documentation now distinguishes the V0.1 LMS revival milestone from the
  V1.0 estimator-comparison portfolio release

## [0.1.0] - 2026-08-13

### Added

- Clean-room MATLAB project bootstrap, configuration, presets, and CI
- Configurable linear and arbitrary 2D microphone geometry
- Deterministic source generation, direct-path propagation, integer delay,
  and windowed-sinc fractional delay
- Independently implemented LMS FIR identification and signed peak/phase
  delay estimation
- Exact-TDOA and end-to-end LMS coordinate localization with visible solver
  diagnostics
- Reproducible basic example, plots, selected results, methodology,
  references, provenance, and limitations

[Unreleased]: https://github.com/sasi433/microphone-array-localization/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/sasi433/microphone-array-localization/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/sasi433/microphone-array-localization/releases/tag/v0.1.0
