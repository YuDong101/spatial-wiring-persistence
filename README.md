# Spatial network simulations for Figure 1

MATLAB code for generating the three representative networks, simulating their activity, and calculating the 6,000-network duration curve in Figure 1c.

## Files

| File | Purpose |
| --- | --- |
| `generate_representative_networks.m` | Generate networks at exact α = 0.1, 0.9 and 2. |
| `simulate_representative_networks.m` | Simulate the three networks and export spike rasters and population firing rates. Also contains the shared simulation solver. |
| `generate_scan_networks.m` | Generate 60 logarithmically spaced α values from 0.1 to 5, with 100 realisations each. Uses the first file's generator. |
| `compute_fig1c.m` | Simulate all 6,000 scan networks using the shared solver, calculate durations, and plot Figure 1c. |
| `neuron_coordinates.mat` | Neuron positions, identifiers and source attribution. |
| `README.md` | Installation, execution and data attribution. |

Keep these six files in the same directory. All helper functions are included in the four `.m` files.

## Requirements

- MATLAB; tested with R2026a on Windows.
- Base MATLAB is sufficient for sequential execution. Parallel Computing Toolbox is optional for multiple process workers.
- No external downloads or Brain Connectivity Toolbox are required.

## Run

Open MATLAB in this directory and run:

```matlab
% 1. Generate the three representative networks.
generate_representative_networks;

% 2. Simulate them and export rasters and firing rates.
simulate_representative_networks;

% 3. Generate the 6,000 scan networks.
generate_scan_networks;

% 4. Simulate the scan and calculate Figure 1c.
figureDir = compute_fig1c;
```

The fourth step performs the full simulation ensemble and takes substantially longer than network generation. To use 16 process workers, replace the last command with:

```matlab
figureDir = compute_fig1c([], 16);
```

Choose a worker count appropriate for your computer. A single representative simulation took approximately 24 seconds in the validation environment; full-scan runtime depends on hardware and parallel overhead.

### Resume a scan

Each completed network is saved separately. Repeating `compute_fig1c` checks and reuses completed simulations. To limit each invocation to 100 new networks:

```matlab
figureDir = compute_fig1c([], 16, 100);
```

Repeat this command until all 6,000 networks are complete. `figureDir` is empty while simulations remain unfinished. Input and code hashes protect checkpoint reuse; changing them requires a new results directory. Generation refuses to overwrite existing network files, so run steps 1 and 3 once.

## Model and outputs

Each directed network contains **200 neurons and 3,879 edges**, without self-connections. Edge sampling weights are proportional to distance raised to −α, with β = λ = 0. Neuron samples and external-input seeds are paired across α. Fixed seeds reproduce the production networks.

The representative values are exactly **0.1, 0.9 and 2**. The scan uses `logspace(log10(0.1), log10(5), 60)`; its nearest samples to 0.9 and 2 are separate conditions. Each scan condition has 100 realisations.

Simulations use a 0.01-ms time step, AMPA/NMDA conductances of 0.125/0.14, and the standard refractory-first event rule. The cue runs between 500 and 1,000 ms. Simulation continues to 5,100 ms, including a 100-ms silence-confirmation interval. Duration is measured from cue offset to the beginning of the first confirmed 100-ms silent window, capped at 4,000 ms. Figure 1c shows the mean and **sample standard deviation** across 100 networks per α.

Outputs are created in `results/`:

- `representative_networks.mat` and `scan_networks.mat`: adjacency matrices, sampled coordinates, identifiers and seeds.
- `representative_simulation/`: per-network spike events and states, duration summary, and `Fig1b.pdf` / `Fig1b.png`.
- `scan_simulation/`: resumable simulation checkpoints and a duration summary. Once complete, a new `figure_*` subdirectory contains `Fig1c.pdf`, `Fig1c.png`, `Fig1c_data.mat` and `Fig1c_summary.csv`.

The exported panels provide the representative activity and duration curve. The anatomical illustration in Figure 1a and the manuscript's combined page layout are outside this six-file package.

## Neuron coordinates and attribution

`neuron_coordinates.mat` contains `points` (139,255 × 3, in nanometres), `root_id` (`uint64`), `coordinate_units`, and `provenance`. It retains the first recorded coordinate per neuron and the original row order, without spatial transformations. These positions provide spatial inputs for the generated model networks.

The coordinates originate from the **FlyWire FAFB v783** public release: [coordinates](https://storage.googleapis.com/flywire-data/codex/data/fafb/783/coordinates.csv.gz) and [neuron identifiers](https://storage.googleapis.com/flywire-data/codex/data/fafb/783/neurons.csv.gz). FlyWire distributes these data under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/); see its [data-use guidelines](https://home.flywire.ai/guidelines). This package extracts the coordinates and identifiers into MATLAB format. The data licence applies to this supplied dataset.

Please acknowledge the dataset:

> Dorkenwald, S. et al. Neuronal wiring diagram of an adult brain. *Nature* **634**, 124–138 (2024). [doi:10.1038/s41586-024-07558-y](https://doi.org/10.1038/s41586-024-07558-y).

## Validation

All three representative networks and all 6,000 scan networks were generated and compared with the frozen production inputs: adjacency matrices, sampled coordinates, identifiers and seeds matched exactly. All three representative simulations matched the production spike events and final states exactly. Their observed durations were 1,696.46, 2,290.47 and 4,000 ms, respectively.

The Figure 1c aggregation was checked against the frozen 6,000-network simulation results. Means, sample standard deviations and endpoint counts matched exactly. The full 6,000-network simulation ensemble was not rerun during packaging.
