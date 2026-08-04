# Accelerated Implementation Plan

## Purpose and scope

This roadmap organizes the clean-room reconstruction into approximately 16 active development days. The initial product is a reproducible MATLAB simulation of one stationary sound source in a synthetic, direct-path, free-field environment. It is not an artificial-intelligence system, a real-time system, a complete room-acoustics model, or a production localization product.

Work proceeds incrementally. Each commit must be implemented, validated, reviewed, and pushed before work starts on the next commit. Generated experiment output remains local under `results/` unless a result is deliberately selected for documentation.

## Development phases

| Phase | Days | Outcome |
| --- | --- | --- |
| Foundation and automation | Pre-trial, 1-2 | Reproducible MATLAB environment, configuration, tests, and CI |
| Simulation components | 3-6 | Geometry, deterministic signals, noise, and integer/fractional delays |
| Localization core | 7-10 | Exact-TDOA localization, clean-room LMS, delay estimation, and an end-to-end pipeline |
| V0.1 milestone | 11 | Reproducible LMS demonstration, plots, methodology, and limitations |
| Evaluation and comparison | 12-14 | Seeded SNR experiments and an independent GCC-PHAT comparison |
| Hardening and release | 15-16 | Regression coverage, diagnostics, documentation, and V1.0 release preparation |

## Commit sequence

### Pre-trial foundation

1. `chore: track planned project directories`
2. `docs: add accelerated implementation roadmap`

### Day 1: MATLAB and VS Code automation

1. `chore: document MATLAB development environment`
2. `chore: add MATLAB project path bootstrap`
3. `test: add MATLAB smoke test and test runner`
4. `chore: add VS Code MATLAB tasks`
5. `docs: add Codex-assisted local workflow`

### Day 2: configuration and continuous integration

1. Add the default simulation configuration.
2. Add historical-style and modern presets.
3. Validate all public configuration fields.
4. Test valid and invalid configurations.
5. Run MATLAB tests in GitHub Actions on pushes and pull requests.

### Day 3: geometry and propagation

1. Create configurable linear arrays.
2. Validate arbitrary two-dimensional microphone coordinates.
3. Calculate source-to-microphone distances and arrival times.
4. Test geometry with hand-calculated cases.
5. Document reference microphones and linear-array mirror ambiguity.

### Day 4: deterministic source signals

1. Generate seeded Gaussian broadband signals.
2. Add a deterministic chirp option.
3. Add normalization and signal-power utilities.
4. Test reproducibility, sample counts, and normalization.

### Day 5: integer delays and noise

1. Implement integer delays with explicit sign and padding conventions.
2. Simulate integer-delayed microphone channels.
3. Add deterministic noise at a measured target SNR.
4. Test delay alignment and measured SNR.
5. Document direct-path simulation assumptions.

### Day 6: fractional delays

On `feature/fractional-delay`, document and independently implement a windowed-sinc FIR fractional delay, including group-delay compensation and output alignment. Validate impulse, broadband, zero-delay, integer-delay, fractional-delay, and multichannel cases before merging.

### Day 7: localization from exact TDOAs

On `feature/source-localization`, predict TDOAs, form residuals using every non-reference microphone, solve with `lsqnonlin`, preserve solver diagnostics, calculate localization metrics, and test exact, constrained-linear, mirror, non-collinear, degenerate, and failure cases.

### Days 8-9: clean-room LMS and delay estimation

On `feature/lms-delay-estimation`, document the standard LMS equations and independently implement the adaptive filter without historical helper code. Test FIR identification and validation failures, expose convergence diagnostics, support signed relative delays, and estimate delay from both impulse-response peaks and unwrapped phase slopes.

### Day 10: end-to-end LMS localization

Assemble configuration, signal generation, propagation, microphone simulation, noise, LMS TDOA estimation, coordinate estimation, metrics, and diagnostics into a deterministic pipeline. Add clean and noisy integration tests plus a basic example.

### Day 11: visualization and V0.1.0

Add plots for geometry, TDOAs, LMS convergence, and learned filters. Complete methodology, limitations, references, reproducible selected results, and the README. Tag and release `v0.1.0` only after all local tests and CI pass and the basic example succeeds from a clean MATLAB process.

### Day 12: repeated SNR experiments

Add seeded Monte Carlo trials, configurable SNR sweeps, error summaries, solver-failure counts, exports, plots, and compact deterministic CI tests.

### Days 13-14: GCC-PHAT and estimator comparison

On `feature/gcc-phat`, independently implement GCC-PHAT with FFT operations, physical lag bounds, and documented sub-sample interpolation. Test signed clean and noisy delays, integrate selectable estimators, compare all methods on identical signals, and document the limitations honestly.

### Day 15: regression and quality hardening

Add code analysis, microphone-count regressions, protection against omitted residual terms, degenerate-geometry and solver-failure tests, improved diagnostics, and useful CI artifacts.

### Day 16: V1.0.0 portfolio release

Finalize architecture, methodology, references, provenance, licensing, limitations, selected reproducible results, changelog, citation metadata, and the release checklist. Tag and release `v1.0.0` only after every acceptance gate passes.

## Branch policy

Routine, small, low-risk work may be committed directly to `main`. Higher-risk numerical or architectural work must use a focused branch, including:

- `feature/fractional-delay`
- `feature/source-localization`
- `feature/lms-delay-estimation`
- `feature/gcc-phat`

Other branches should use `feature/`, `fix/`, `experiment/`, or `refactor/`. Commits use Conventional Commit-style prefixes and must not mix unrelated work. Published history must not be amended, rebased, force-pushed, or reset without explicit approval.

Feature work is merged only after focused tests, the complete local suite, and CI pass. Individual commits should be preserved unless a different merge strategy is explicitly approved.

## MATLAB test policy

Every mathematical stage must be testable independently. Tests use deterministic seeds and cover successful cases, boundary conditions, invalid inputs, numerical failure states, and documented ambiguities.

Once the bootstrap and runner exist, the standard command is:

```powershell
matlab -batch "run_tests"
```

Until that runner is established, use:

```powershell
matlab -batch "setupProject; results = runtests('tests', IncludeSubfolders=true, InvalidFileFoundAction='error'); assert(~isempty(results), 'No MATLAB tests were discovered'); assert(all([results.Passed]), 'MATLAB tests failed');"
```

A focused test uses the same assertions against a selected test file. A passing result may be claimed only when MATLAB runs, exits successfully, discovers the required tests, and reports that every required test passed. Assertions must not be weakened merely to obtain a green result.

Before each implementation commit, run relevant focused tests. Run the accumulated complete suite before pushing implementation changes and at every release gate. Documentation-only or directory-only commits may use static validation when MATLAB execution cannot exercise their content.

## Continuous-integration policy

GitHub Actions will run the MATLAB test suite for pushes to `main` and pull requests targeting `main`, using official MathWorks actions where appropriate. CI must use the repository bootstrap and documented test runner so local and hosted validation exercise the same paths.

CI should eventually publish useful test and coverage artifacts, but a coverage percentage is not a substitute for meaningful mathematical tests. No implementation change may be merged while required CI checks fail.

## V0.1.0 release criteria

The historical-revival milestone requires:

- A clean-room LMS implementation with independent tests.
- Configurable microphone geometry and deterministic source generation.
- Tested integer and fractional propagation delays.
- Exact-TDOA localization before estimated-TDOA localization.
- An end-to-end deterministic LMS example.
- Visible actual and estimated coordinates, error in metres, and solver diagnostics.
- Documented linear-array mirror ambiguity and direct-path limitations.
- Passing local tests and GitHub Actions.
- A basic example that runs from a clean MATLAB process.
- Reproducible methodology, references, provenance, limitations, and selected figures.
- No historical or uncertain third-party source code.

## V1.0.0 release criteria

The portfolio release additionally requires:

- Repeated seeded SNR experiments and summary statistics.
- An independently implemented and tested GCC-PHAT estimator.
- An honest LMS versus GCC-PHAT comparison on identical signals.
- Regression tests for multiple microphone counts and arbitrary valid 2D coordinates.
- Verification that every non-reference microphone affects localization.
- Measurable solver failures and strengthened diagnostics.
- Final architecture, release, citation, licensing, and reproducibility documentation.
- Passing local tests, CI, documented examples, and the full acceptance checklist.

## Trial buffer policy

Days 17-30 are contingency for compatibility, toolbox, numerical-stability, convergence, delay-sign, alignment, tolerance, CI, plotting, documentation, and experiment-rerun issues. They are not an invitation to add major scope. Real recordings, reverberation, multiple sources, tracking, 3D arrays, hardware integration, synchronization, and calibration remain future work.

## Clean-room constraints

The historical repository may be consulted only for broad intent, behaviour, inputs, outputs, known defects, and academic context. Do not inspect historical source unless an explicit high-level comparison is requested.

In particular, this project must not copy, translate, adapt, or reconstruct the historical `lms.m` or `convm.m`; reproduce their comments, names, control flow, or implementation structure; import historical Git history; or claim ownership of third-party code. Algorithms must be implemented independently from mathematical definitions and properly cited authoritative references.

The MIT License applies only to newly written repository content. Historical source, uncertain third-party helpers, unlicensed assets, credentials, generated experiment output, and large unapproved data files must not be committed.
