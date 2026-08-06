# Array Geometry and Propagation Conventions

## Coordinate system and units

The simulation uses Cartesian coordinates in two dimensions. All source and microphone coordinates are expressed in metres. Angles are expressed in radians, time in seconds, sampling frequency in hertz, and propagation speed in metres per second.

`micloc.createLinearArray` defines a linear array by its microphone count, adjacent-microphone spacing, centroid, and orientation. The centroid is the coordinate supplied as `originMeters`. An orientation of zero points along the positive x-axis; positive angles rotate counterclockwise. Microphones are ordered from the negative-axis end to the positive-axis end.

The function supports odd and even microphone counts. With an even count, the centroid lies midway between the two central microphones rather than at a microphone position.

Arbitrary valid arrays are represented by an `N × 2` matrix:

```text
[x1, y1
 x2, y2
 ...
 xN, yN]
```

Rows must be finite and unique, and the current localization plan requires at least three microphones. Valid linear arrays are deliberately accepted even though their ambiguity must be handled explicitly.

## Direct-path distance and arrival time

For source position `s = [x, y]` and microphone position `m_i`, the direct-path distance is

```text
d_i = ||m_i - s||_2
```

With propagation speed `c`, the ideal arrival time is

```text
t_i = d_i / c
```

These calculations model only geometric free-field propagation. They do not include emission time, reflections, reverberation, microphone response, clock mismatch, or hardware synchronization error.

## Reference microphone and relative arrival time

One microphone is selected by `referenceMicrophoneIndex`. It is an ordinary array element used as the common comparison channel; it is not an additional sensor or a special physical microphone.

For reference microphone `r`, this project defines the relative arrival time, or TDOA, for microphone `i` as

```text
TDOA(i, r) = t_i - t_r = (d_i - d_r) / c
```

Under this convention:

- A positive TDOA means the signal arrives at microphone `i` later than at the reference.
- A negative TDOA means it arrives at microphone `i` earlier.
- The reference microphone has a TDOA of exactly zero relative to itself.

Later delay-estimation stages must document any sample-lag or filter-delay convention and convert it explicitly to this geometric convention. Sign changes must never be implicit.

## Linear-array mirror ambiguity

A source and its reflection across the line containing a linear array have identical distances to every microphone on that line. They therefore produce identical ideal arrival times and TDOAs. No localization algorithm using only those direct-path measurements can distinguish the two positions.

For a horizontal array on the x-axis, `[x, y]` and `[x, -y]` are the mirror pair. Reporting only one of them without stating a constraint would hide a genuine ambiguity rather than solve it.

The planned linear-array experiments choose the positive-y half-plane by constraining the localization bounds so that `y >= 0`. For a rotated or translated line, the equivalent constraint must use a consistently selected side of that line rather than assuming that the global y-coordinate alone identifies the side.

## Non-collinear alternative

A valid non-collinear array can remove this exact planar mirror symmetry because at least one microphone lies away from the line shared by the others. Non-collinearity does not guarantee good localization: accuracy still depends on aperture, source position, bandwidth, sampling rate, delay error, noise, and numerical conditioning.

Both linear and non-collinear geometries remain supported. Tests and result reports must identify the geometry and any half-plane constraint used so that apparently accurate coordinates are not presented without their underlying assumptions.
