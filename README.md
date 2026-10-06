# Representative spatial-network simulations

Minimal simulation code accompanying **Spatial wiring tunes a crossover in
persistent activity associated with working memory**.

The package generates and simulates three new networks at the exact spatial
exponents **0.1, 0.9 and 2**. Each network contains 200 excitatory neurons.
The three conditions share the same selected coordinates and an edge budget
of 2,000 directed edges each. Their edge sets are sampled separately.
All simulation results are generated when the code runs.

## Requirements

- MATLAB with its standard JVM enabled. The package uses base MATLAB only.
- User-supplied three-dimensional neuronal coordinates (at least 200 rows).
- Approximately 1 GB of available memory in addition to MATLAB's baseline
  memory use. The simulator's dense spike buffer alone uses about 800 MB.

The package is self-contained: add this directory to the MATLAB path.
It requires no BCT, Python, parallel pool or files from the parent project.
See `VALIDATION.md` for the versions and checks actually exercised.

## Coordinate data

FlyWire v783 neuronal coordinates are available through
[FlyWire Codex](https://codex.flywire.ai/), as stated in the manuscript's
Data availability section. Obtain the data from that source and follow its
access and use conditions. No third-party coordinate data are distributed here.

Reference: Dorkenwald et al., *Neuronal wiring diagram of an adult brain*,
Nature 634, 124–138 (2024),
[doi:10.1038/s41586-024-07558-y](https://doi.org/10.1038/s41586-024-07558-y).

Prepare one of these formats:

- **CSV:** numeric columns named `x`, `y`, `z`; additional columns are ignored.
- **MAT:** a numeric `points` matrix, with one neuron per row and three columns.
- **MAT:** a structure `whole_v783` containing the same matrix in `.points`.

These are input contracts for this code, not a claim that Codex exports those
exact formats. Convert your acquired coordinates into one of them. Retain the
dataset version and conversion record. Row order determines the seeded sample.
All three axes must use the same physical length unit. The code computes 3D
Euclidean distances without projection, reflection, rotation or per-axis scaling.
Uniform scaling of all coordinates leaves the distance-only sampling law unchanged.
Nonfinite coordinates and coincident positions among selected neurons are rejected.

## Run

Open MATLAB in this directory, or add its absolute path:

```matlab
addpath('/path/to/public_reproduction');
runDir = run_representative('/path/to/coordinates.csv');
```

For a MAT input and an explicit output parent directory:

```matlab
runDir = run_representative('/path/to/coordinates.mat', '/path/to/results');
```

Each invocation creates a unique `run_<UUID>` directory. Existing runs are
preserved. Simulations run sequentially. Each completed condition is saved
immediately; if a run is interrupted, its completed files remain available.
A new invocation starts a new run; this small package has no resume mechanism.

The input coordinate path is required. There is no fallback to synthetic or
precomputed scientific data. Synthetic coordinates appear only in unit tests.
