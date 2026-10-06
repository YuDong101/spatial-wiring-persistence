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

## Outputs

| File | Contents |
|---|---|
| `networks.mat` | `networks`: selected coordinates, source row indices, exact alpha values and logical adjacency matrices; `cfg`: parameters and seeds; `source`: coordinate filename, bytes and SHA-256; `runtime`; `code`: source-code hashes |
| `condition_01.mat` | Simulator output for alpha 0.1 |
| `condition_02.mat` | Simulator output for alpha 0.9 |
| `condition_03.mat` | Simulator output for alpha 2 |
| `summary.csv` | Exact alpha, recorded duration, total spike count and endpoint flag |

Each condition MAT contains `result` and `cfg`. `result.spikeTimesMs` and
`result.spikeNeuronIndex` are aligned vectors, ordered by event time.
Neuron indices are one-based and refer to the selected coordinate rows.
Adjacency `networks.adjacency(:,:,k)` uses **rows as sources**: `A(j,i)=1`
means neuron j projects to neuron i.

`total_spike_count` includes the entire simulated trajectory, including the
pre-cue and cue periods. `postCueRateHz` is the original simulator's spike
count after 1,000 ms divided by the fixed 4-s delay, for each neuron.
No additional physical-quantity analysis or plotting is included.

## Model and reproducibility

`+wmrep/config.m` records the parameters. Network generation uses 3D distance
weights `d^(-alpha)` and weighted sampling without replacement. It produces
binary directed networks with no self-connections. An exponential-race sampler
implements this law without a Statistics and Machine Learning Toolbox dependency.

The coordinate seed is `20261006`; network seeds are `[101, 102, 103]`.
Coordinates and the edge budget are fixed across conditions. Local random
streams keep network generation independent of the caller's random state.
The dynamics uses seed 1 for every condition, preserving the original shared
random driving-input convention. The runner restores the caller's RNG state.

The dynamics is the manuscript's forward-Euler LIF implementation, with
recurrent AMPA/NMDA and external AMPA input. It uses a 0.01-ms time step and
ends no later than 5,000 ms. Baseline external drive is 800 Hz; the cue raises
it to 1,600 Hz during the simulator's 500–1,000-ms interval.
Conductances are `gAMPA_R=0.135`, `gNMDA_R=0.14`, `gAMPA_ext=0.3`,
`gGABA_R=0.4`, with `gPoisson=1`. All nodes are excitatory.

The simulator detects a complete 100-ms silent window after cue offset.
It records duration from cue offset to that window's start. If no such window
is confirmed before simulation ends, the recorded value is 4,000 ms.
This value is an endpoint code, not a strict lower bound on a backdated
silence onset. The fixed timing and simulation-seed fields in `config.m`
document constants implemented inside `trial.m`.

Spatial-rule background: Zhang et al., *Geometric Scaling Law in Real Neuronal
Networks*, Physical Review Letters 133, 138401 (2024),
[doi:10.1103/PhysRevLett.133.138401](https://doi.org/10.1103/PhysRevLett.133.138401).

## Scope

This release demonstrates the paper's model using three newly generated networks.
The demo edge budget is exactly 2,000 for all three conditions. The manuscript
ensemble used repeat-specific budgets averaging 2,000.53, with SD 14.05.
The manuscript's sampled values labelled 0.9 and 2 were approximately
0.891807988644399 and 1.9761712629005. This release instead computes **exactly
0.9 and 2**, as configured for the public example.

The package reproduces the simulation method. It does not recreate the original
selected network identities or guarantee their durations. Each condition has one
network; its outcome is not an ensemble estimate. The 6,000-network sweep,
prediction experiments, physical-quantity analyses and manuscript figure builders
are outside this release.

The package includes neither anatomy images nor coordinate or simulation data.
It generates no anatomical renderings. `PROVENANCE.md` records the code origin.

## Tests

From this directory:

```matlab
results = runtests('tests/test_public_package.m');
assertSuccess(results);
```

Tests construct synthetic coordinates in memory to check input handling,
repeatability, edge budgets and unit invariance. A silent-network test exercises
the actual simulator. They do not require or redistribute FlyWire data.
