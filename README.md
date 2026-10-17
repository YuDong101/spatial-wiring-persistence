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

## Neuron coordinates and attribution

`neuron_coordinates.mat` contains `points` (139,255 × 3, in nanometres), `root_id` (`uint64`), `coordinate_units`, and `provenance`. It retains the first recorded coordinate per neuron and the original row order, without spatial transformations. These positions provide spatial inputs for the generated model networks.

The coordinates originate from the **FlyWire FAFB v783** public release: [coordinates](https://storage.googleapis.com/flywire-data/codex/data/fafb/783/coordinates.csv.gz) and [neuron identifiers](https://storage.googleapis.com/flywire-data/codex/data/fafb/783/neurons.csv.gz). FlyWire distributes these data under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/); see its [data-use guidelines](https://home.flywire.ai/guidelines). This package extracts the coordinates and identifiers into MATLAB format. The data licence applies to this supplied dataset.

Please acknowledge the dataset:

> Dorkenwald, S. et al. Neuronal wiring diagram of an adult brain. *Nature* **634**, 124–138 (2024). [doi:10.1038/s41586-024-07558-y](https://doi.org/10.1038/s41586-024-07558-y).
