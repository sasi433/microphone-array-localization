# Project Provenance and Clean-Room Policy

## Historical background

This repository reconstructs an earlier academic MATLAB project that simulated the localization of an unknown sound source using a linear microphone array.

The historical implementation broadly included:

* Synthetic source-signal generation
* Microphone propagation-delay simulation
* Adaptive filtering
* Delay estimation from phase behaviour
* Equations relating relative arrival delays to source coordinates
* Iterative source-position estimation

The original repository is preserved privately as a historical reference.

## Third-party source concern

The historical repository contained MATLAB helper files named `lms.m` and `convm.m`.

Comments in those files attributed them to M. H. Hayes and the 1996 textbook *Statistical Digital Signal Processing and Modeling*. The original redistribution terms and licensing conditions have not been verified.

Those files are therefore excluded from this repository.

## Clean-room implementation rules

This repository will not:

* Import the historical repository’s Git history
* Copy uncertain third-party source files
* Translate uncertain source files into another implementation language
* Copy their comments, variable naming, control flow, or implementation structure
* Relicense or claim ownership of historical third-party material

Required algorithms will instead be implemented independently using:

* Standard mathematical definitions
* MATLAB and MathWorks documentation
* Clearly cited textbooks and academic papers
* Original tests developed for this repository

## Historical project ownership

The underlying academic problem, experiment goals, configuration choices, analysis, and project context are part of the author’s historical academic work.

Where historical implementation work or helper code has uncertain authorship or licensing, this repository will describe that context honestly and will not republish the material.

## Licensing boundary

The repository’s MIT License applies only to newly written source code, tests, documentation, configuration, and original assets committed to this repository.

It does not apply to:

* Files retained only in the private historical repository
* Third-party publications
* Referenced mathematical material
* External datasets or assets not included in this repository

## References

Conceptual and mathematical references will be recorded separately as the implementation is developed.

Citing a publication as a conceptual reference does not mean that source code from that publication has been copied into this project.
