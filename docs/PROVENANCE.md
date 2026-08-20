# Project provenance and clean-room policy

## Historical background

This repository independently reconstructs the intent of an earlier academic
MATLAB project that simulated localization of an unknown sound source with a
linear microphone array. The historical work established the academic
problem, experiment goals, inputs, outputs, and high-level processing stages.
The historical repository remains private and its Git history is not part of
this repository.

## Excluded historical helper source

The historical repository contained MATLAB helper files named `lms.m` and
`convm.m`. Comments in those files attributed them to M. H. Hayes and the
1996 textbook *Statistical Digital Signal Processing and Modeling*. Their
redistribution terms have not been verified, so neither file is distributed
or used as a line-by-line implementation specification.

This repository does not copy, translate, adapt, or reconstruct those files,
their comments, naming, control flow, implementation structure, or historical
Git history. It does not claim ownership of them.

## Independent implementation basis

Repository algorithms were developed from:

- Standard mathematical definitions
- Publicly described signal-processing methods
- MATLAB and MathWorks product documentation
- Publications listed in [`REFERENCES.md`](REFERENCES.md)
- Original tests and explicit repository design records

References establish concepts and documented API behaviour. Citation does not
mean that publication, MathWorks, or historical source code was copied.

## Ownership and licensing boundary

The [MIT License](../LICENSE) applies to newly written source code, tests,
documentation, configuration, and original assets committed to this
repository. It does not apply to:

- Files retained only in the private historical repository
- Excluded historical or uncertain third-party helper source
- Referenced publications or their contents
- MATLAB or MathWorks products and documentation
- External datasets or assets that are not included here

MATLAB, Signal Processing Toolbox, and Optimization Toolbox are external
runtime dependencies governed by their own MathWorks terms. They are not
vendored or relicensed by this repository.

## V1.0 tracked-content audit

The tracked release candidate was audited on 20 August 2026 using the Git
index and repository history. The audit found:

- No tracked `lms.m`, `convm.m`, historical source tree, or imported
  historical Git history
- No tracked recordings, video, external datasets, large MAT-files, or
  vendored third-party packages
- No copied Hayes helper comments or claims of ownership over excluded code
- Three tracked PNG figures, all reproducibly generated from synthetic data
  by [`examples/generateV01Figures.m`](../examples/generateV01Figures.m) and
  the repository's plotting functions
- No credentials, tokens, MATLAB autosaves, or generated local result files
  in the tracked release content

This is a repository-content audit, not a legal opinion. Future contributions
must preserve the same boundary and document the provenance and licence of any
new external asset before it is committed.
