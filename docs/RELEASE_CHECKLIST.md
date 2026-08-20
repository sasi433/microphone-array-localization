# V1.0.0 release checklist

This checklist separates repository acceptance from the external tag and
GitHub release operations. Check repository gates before creating the tag;
verify publication immediately afterward. Do not move or replace a published
tag to conceal a failed gate.

## Release identity and scope

- [x] Version is `1.0.0` in `CITATION.cff` and `CHANGELOG.md`.
- [x] Release date is recorded as 20 August 2026.
- [x] The release remains a single-source, synthetic, synchronized,
  two-dimensional, direct-path MATLAB simulation.
- [x] Real recordings, reverberation, multiple sources, tracking, 3D arrays,
  hardware synchronization, and calibration remain documented future work.
- [x] No AI, production, real-time, room-model, or commercial-performance
  claim is made.

## Mathematical and executable gates

- [x] Geometry, propagation, integer/fractional delays, LMS, phase delay,
  GCC-PHAT, exact localization, and end-to-end pipelines have focused tests.
- [x] Regression tests cover 4, 6, and 8 microphones and arbitrary valid 2D
  coordinates.
- [x] Every non-reference microphone contributes to the localization
  residual vector and objective.
- [x] Degenerate geometry, ambiguity, invalid input, and solver-limit states
  are visible and tested.
- [ ] Run `matlab -batch "run_code_analysis"` on the final release commit.
- [ ] Run `matlab -batch "run_tests"` on the final release commit and record
  the discovered/pass/fail/incomplete totals.
- [ ] Run the basic example from a clean MATLAB process and record its seed,
  actual/estimated coordinates, error, and solver state.
- [ ] Run `examples/generateV10Figures.m` on the final release commit and
  confirm the documented deterministic summary.

## Documentation, reproducibility, and provenance

- [x] Architecture and methodology match the implemented selectable-estimator
  pipeline.
- [x] References distinguish mathematical concepts and API behaviour from
  source-code ownership.
- [x] Provenance records the clean-room boundary and dated tracked-content
  audit.
- [x] Limitations and future work state the simulation's non-claims.
- [x] Selected figures record exact configurations, seeds, trial counts, and
  interpretation limits.
- [x] `CHANGELOG.md`, `CITATION.cff`, and the MIT licensing boundary are
  present.
- [ ] Verify all README and release-document relative links on the final
  release commit.

## Repository and CI gates

- [ ] Confirm the final working tree is clean on `main`.
- [ ] Confirm local `main` and `origin/main` have zero divergence.
- [ ] Confirm GitHub MATLAB CI passes on the final release commit.
- [ ] Confirm the CI artifact contains JUnit test results and Cobertura
  coverage XML.
- [ ] Confirm tracked files contain no credentials, generated `results/`,
  excluded historical helpers, unlicensed media/data, or unexpected large
  binaries.

## Tag and publication procedure

After every repository and CI gate above passes:

1. Create annotated tag `v1.0.0` at the verified `main` commit.
2. Push only that tag to `origin` and confirm local/remote tag object and
   peeled commit match.
3. Publish a non-draft, non-prerelease GitHub release titled
   `v1.0.0 - portfolio release` using the verified changelog and documented
   limitations.
4. Confirm the release targets the tagged commit and its source archives are
   available.
5. Confirm GitHub recognizes `CITATION.cff` and exposes citation metadata.
6. Recheck that `main` remains clean and synchronized; do not create another
   source commit solely to mark this procedural checklist complete.

## Publication record

Record these values in the release notes and implementation handoff:

- Release commit SHA
- Annotated tag object SHA and peeled commit SHA
- Final local MATLAB totals
- Final GitHub Actions run URL
- CI artifact name and contents
- GitHub release URL and publication state
