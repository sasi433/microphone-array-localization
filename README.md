# Microphone Array Localization

A clean-room MATLAB reconstruction and modernization of an earlier academic sound-source localization simulation.

> **Project status:** Repository planning and foundation. The localization implementation has not yet been added.

## Overview

This project explores the estimation of an unknown sound-source position using signals received by a configurable microphone array.

It revives an earlier MATLAB academic experiment while improving its structure, reproducibility, testing, numerical reporting, and documentation. The first release will remain a focused simulation rather than presenting itself as a production acoustic-localization system.

## Initial V0.1 goals

The first release is expected to include:

* Configurable two-dimensional microphone positions
* A default six-microphone linear-array experiment
* Deterministic synthetic source-signal generation
* Direct-path propagation-delay simulation
* Optional additive noise
* Independently implemented LMS-based delay estimation
* Source-position estimation from relative delays
* Actual and estimated source-coordinate comparison
* Localization error reported in metres
* Reproducible plots and experiment settings
* MATLAB unit tests
* Clear mathematical and experimental documentation

The detailed implementation sequence will be finalized before development begins.

## Scope and limitations

The first release will model:

* One stationary sound source
* Synchronized microphones
* A known and configurable speed of sound
* Direct-path or free-field propagation
* Synthetic signals
* Two-dimensional localization

The first release will not claim to support:

* Real-time audio processing
* Production acoustic localization
* Multiple simultaneous sources
* Real microphone hardware
* Room reflections or reverberation
* Three-dimensional localization
* Source tracking
* Machine learning or artificial intelligence

A linear microphone array also has a mirror-position ambiguity unless the source is constrained to a known side of the array. This limitation will be documented and tested rather than hidden.

## Clean-room reconstruction

The historical MATLAB repository contained helper functions whose comments attributed them to M. H. Hayes and a 1996 textbook. Their redistribution permissions have not been verified.

Therefore:

* The historical repository is retained privately as a reference.
* Its Git history is not imported into this repository.
* Its third-party helper files are not copied, translated, or republished here.
* Required algorithms will be implemented independently from mathematical definitions and cited references.
* Only newly written code and assets with clearly compatible licensing will be included.

Additional details are documented in [`docs/PROVENANCE.md`](docs/PROVENANCE.md).

## Planned repository structure

```text
.
├── docs/       Project methodology, provenance, limitations, and references
├── examples/   Reproducible demonstration and experiment scripts
├── results/    Generated local results, normally excluded from Git
├── src/        Reusable MATLAB implementation functions
└── tests/      MATLAB unit and integration tests
```

## Development workflow

Routine, small, reviewable changes may be committed directly to `main`.

Separate branches will be used for changes with higher numerical or architectural risk, such as:

* LMS reconstruction
* Fractional-delay processing
* Localization-optimizer replacement
* GCC-PHAT experiments
* Large multi-file refactoring

Every implementation commit should include relevant tests or be followed immediately by a clearly related test commit.

## Technology

The first release will use MATLAB.

Local MATLAB installation, toolbox requirements, test commands, and supported MATLAB versions will be documented once the implementation environment is finalized.

## License

The newly written code and documentation in this repository are licensed under the MIT License.

This license does not apply to code from the historical repository or to third-party material that is not included here.
