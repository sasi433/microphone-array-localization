# Development Environment

## Verified local environment

The following environment was verified on 4 August 2026 from the repository's VS Code terminal:

| Component | Verified value |
| --- | --- |
| Operating system | Windows, version 25H2, build 26200.8875, x64 |
| Repository | `C:\Users\sasi4\Documents\GitHub\microphone-array-localization` |
| MATLAB release | R2026a Update 4 |
| MATLAB version | 26.1.0.3312084 |
| MATLAB root | `C:\Program Files\MATLAB\R2026a` |
| MATLAB executable | `C:\Program Files\MATLAB\R2026a\bin\matlab.exe` |
| VS Code | 1.131.0, x64 |
| MATLAB extension for VS Code | Official MathWorks extension, `mathworks.language-matlab` 1.3.13 |

The `matlab` command resolves on `PATH` and starts successfully in non-interactive batch mode. The extension is installed locally, and the same executable is available to VS Code terminal tasks. The extension's interactive status indicator cannot be validated by a batch command; confirm that it reports MATLAB as connected when using editor features.

## Required MathWorks products

The local installation contains only the products currently required by the plan:

| Product | Version | Purpose |
| --- | --- | --- |
| MATLAB | 26.1 (R2026a) | Language, test framework, FFT operations, and simulation runtime |
| Signal Processing Toolbox | 26.1 (R2026a) | Signal-analysis functions, including `phasez` |
| Optimization Toolbox | 26.1 (R2026a) | Nonlinear least-squares localization with `lsqnonlin` |

The verification command reported `exist('phasez','file') == 2` and `exist('lsqnonlin','file') == 2`. No DSP System Toolbox, Audio Toolbox, Phased Array System Toolbox, Symbolic Math Toolbox, Statistics and Machine Learning Toolbox, Parallel Computing Toolbox, MATLAB Coder, or Simulink dependency is planned for V0.1.

## Environment verification

Run MATLAB's release, installation-root, and product inventory check with:

```powershell
matlab -batch "disp(version); disp(matlabroot); disp(struct2table(ver))"
```

Check the two required toolbox functions with:

```powershell
matlab -batch "fprintf('phasez: %d\n', exist('phasez','file')); fprintf('lsqnonlin: %d\n', exist('lsqnonlin','file'));"
```

Both function checks must print `2`.

## Project setup

Run commands from the repository root. Once `setupProject.m` is present, initialize a MATLAB process with:

```powershell
matlab -batch "setupProject"
```

The bootstrap adds only `src/` to the current MATLAB process. It does not save or permanently modify the MATLAB path.

## Tests

Once `run_tests.m` is present, run the complete suite with:

```powershell
matlab -batch "run_tests"
```

The explicit equivalent is:

```powershell
matlab -batch "setupProject; results = runtests('tests', IncludeSubfolders=true, InvalidFileFoundAction='error'); assert(~isempty(results), 'No MATLAB tests were discovered'); assert(all([results.Passed]), 'MATLAB tests failed');"
```

Run one focused test file with:

```powershell
matlab -batch "setupProject; results = runtests('tests/testProjectSetup.m', InvalidFileFoundAction='error'); assert(~isempty(results), 'No MATLAB tests were discovered'); assert(all([results.Passed]), 'Focused MATLAB tests failed');"
```

A test passes only when MATLAB exits successfully, discovers the expected tests, and reports that all required results passed.

## Code analysis

Run MATLAB Code Analyzer across the repository's root functions and all
MATLAB files below `src/`, `tests/`, and `examples/` with:

```powershell
matlab -batch "run_code_analysis"
```

The command exits with an error if Code Analyzer reports any finding. The
same check runs in MATLAB CI before the complete test suite.

## CI test artifacts

MATLAB CI runs the tests below `tests/` with `src/` on the MATLAB path. Each
completed workflow publishes a `matlab-test-and-coverage` artifact containing
JUnit test results and Cobertura source-coverage XML. The artifact is retained
for 14 days and is uploaded on test failures when MATLAB produced the reports.

Coverage is diagnostic evidence, not the release criterion. Mathematical
correctness remains enforced by focused regression tests and the complete
MATLAB suite.

## VS Code usage

Install and enable the official **MATLAB** extension published by MathWorks. This repository does not require a third-party MATLAB extension. After opening the repository:

1. Confirm that `matlab` resolves in the integrated PowerShell terminal.
2. Confirm that the MATLAB extension status indicates a connected runtime.
3. Run repository commands from the repository root.
4. Use the checked-in tasks after `.vscode/tasks.json` is added.

Do not change the system or user `PATH` solely for this project without explicit approval. If automatic discovery fails, configure the official extension to use the verified executable path shown above.

## Codex-assisted local workflow

Development proceeds one planned commit at a time. Start from a clean working tree on the intended branch and inspect related files before editing. Keep each commit limited to one coherent roadmap item.

Use this verified loop:

```text
edit -> focused tests -> full tests -> diff review -> commit -> push
```

In detail:

1. **Edit:** implement the smallest complete change without modifying unrelated files.
2. **Focused tests:** run the most relevant test file or a documented static check. Preserve exact failures, correct the root cause, and rerun the same check.
3. **Full tests:** run `matlab -batch "run_tests"` for implementation changes. Confirm that tests were discovered, every required test passed, and MATLAB exited successfully.
4. **Diff review:** inspect `git diff`, `git diff --check`, the staged file list, and `git diff --cached`. Confirm that no generated results, credentials, temporary files, or unrelated changes are staged.
5. **Commit:** use the planned Conventional Commit-style message and record the resulting commit SHA.
6. **Push:** push the commit to the intended upstream branch, then verify that the working tree is clean and the local branch is neither ahead of nor behind its upstream.

Do not move to the next planned commit until all six stages succeed. Report the branch, tests and checks, commit SHA, push result, final working-tree state, and next planned commit after every completed change.

## Troubleshooting

### `matlab` is not recognized

Check the installation directly:

```powershell
Get-ChildItem -Directory 'C:\Program Files\MATLAB'
```

Use the verified executable path for the current command or VS Code task. Do not permanently edit `PATH` without approval.

### MATLAB reports a licensing or startup error

Preserve the complete terminal output and verify that MATLAB can start outside VS Code with the release command above. Do not install, activate, or change the trial licence automatically.

### A required function check is not `2`

Use `ver` to determine whether Signal Processing Toolbox or Optimization Toolbox is missing. Stop implementation work that depends on the missing product; do not substitute an unapproved toolbox or external service.

### Tests are not discovered

Run from the repository root, invoke `setupProject`, verify that the requested file exists under `tests/`, and retain `InvalidFileFoundAction='error'`. The full runner must fail when no tests are found.

### Package functions are not found

Run `setupProject` in the current MATLAB process and verify that `src/+micloc/` exists. Do not use `savepath`; project setup must remain session-local.
