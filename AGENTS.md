# AGENTS.md

## Project mission

Reconstruct and modernize an academic microphone-array sound-source localization simulation in MATLAB.

The first release must remain a focused, reproducible signal-processing simulation. Do not present it as an artificial-intelligence system, production acoustic-localization product, real-time system, or complete room-acoustics model.

## Clean-room requirement

This repository is a clean-room reconstruction.

A historical repository may be consulted only to understand the original project’s intent, behaviour, inputs, outputs, and known defects.

Do not:

* Copy source code from the historical repository
* Copy or translate its `lms.m` or `convm.m` files
* Reproduce comments or implementation structure from uncertain third-party files
* Import the historical Git history
* Claim ownership of historical third-party code

Implement required algorithms independently from mathematical definitions and appropriately cited references.

## Initial technology constraint

Use MATLAB for V0.1.

Do not introduce Python, Simulink, machine learning, external web services, Docker, or cloud infrastructure unless a later approved task explicitly requires them.

Avoid unnecessary toolbox dependencies. Document every required MATLAB toolbox.

## Repository structure

Use:

* `src/` for reusable MATLAB functions
* `tests/` for MATLAB unit and integration tests
* `examples/` for executable demonstrations
* `docs/` for methodology, references, provenance, and limitations
* `results/` for generated local output that should normally remain untracked

Keep algorithmic implementation in ordinary `.m` functions. Demonstration scripts and future Live Scripts must call those functions rather than duplicate their logic.

## Engineering standards

* Use descriptive MATLAB names.
* Prefer functions over workspace-dependent scripts.
* Validate public function inputs.
* State units in variable names, documentation, or function help.
* Keep seconds, samples, metres, and metres per second clearly distinguished.
* Use deterministic random seeds for tests and documented experiments.
* Avoid hard-coded microphone counts and manually duplicated calculations.
* Separate signal generation, propagation, delay estimation, localization, metrics, and plotting.
* Document numerical assumptions and known ambiguities.
* Do not silently discard failed solver states or non-convergent results.

## Testing

Every mathematical stage should be testable independently.

Tests should eventually cover:

* Microphone geometry
* Distance and arrival-time calculations
* Integer and fractional delay generation
* LMS behaviour
* Delay estimation
* Localization from exact delays
* End-to-end deterministic simulations
* Invalid input and failure cases

Before local MATLAB is installed, do not claim that MATLAB tests passed. Clearly state that changes received only static review.

After local MATLAB is available, run the complete test suite before pushing implementation changes. The expected non-interactive command will be similar to:

```powershell
matlab -batch "results = runtests('tests', IncludeSubfolders=true); assert(all([results.Passed]), 'MATLAB tests failed');"
```

Adjust the command only when the repository’s documented test runner changes.

## Git workflow

The default branch is `main`.

Routine, small, low-risk tasks may be committed and pushed directly to `main`.

Use a separate branch for higher-risk work, including:

* LMS reconstruction
* Fractional-delay algorithms
* Coordinate-optimizer replacement
* GCC-PHAT
* Large refactoring
* Changes whose numerical correctness cannot yet be verified

Suggested branch prefixes:

```text
feature/
fix/
experiment/
refactor/
```

Use small, meaningful commits following Conventional Commit-style prefixes:

```text
feat:
fix:
test:
docs:
refactor:
chore:
ci:
```

Do not combine unrelated daily-plan tasks into one commit.

Do not push implementation changes when executable tests fail. When MATLAB is unavailable, state that limitation before committing and follow the user-approved validation workflow.

### Codex-assisted commit workflow

Complete planned work one coherent commit at a time. Do not begin the next planned commit until the current commit has been implemented, validated, reviewed, committed, pushed, and confirmed on the intended upstream branch.

For each commit:

1. Confirm that the working tree is clean and the current branch is correct.
2. Inspect the related files before editing.
3. State the intended commit scope and avoid unrelated changes.
4. Implement the smallest complete change.
5. Run the relevant focused MATLAB tests or documented static checks.
6. Fix failures at their root cause and rerun the focused checks.
7. Run the accumulated complete MATLAB suite for implementation changes.
8. Review the unstaged and staged diffs and check for generated or sensitive files.
9. Commit with the planned Conventional Commit-style message.
10. Push to the correct upstream branch and confirm that local and remote histories match.

The verified loop is:

```text
edit -> focused tests -> full tests -> diff review -> commit -> push
```

Report the branch, commit SHA, push result, commands run, outcomes, working-tree status, and next planned commit. Never claim that a MATLAB test passed unless MATLAB executed it successfully.

## Generated and sensitive files

Do not commit:

* Personal access tokens
* Credentials
* MATLAB autosave files
* Temporary workspaces
* Generated experiment output unless explicitly selected
* Large `.mat` files without approval
* Historical third-party files
* Unlicensed audio or image assets
