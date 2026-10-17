# Spatial-wiring-persistence

MATLAB code accompanying the article:

**Spatial wiring tunes a crossover in persistent activity associated with working memory**

**Authors:** Xiuying Zhou and Dong Yu  
**Corresponding author:** Dong Yu (yudong@yangtzeu.edu.cn)

## Files

| File | Purpose |
| --- | --- |
| `generate_representative_networks.m` | Generate three representative networks at α = 0.1, 0.9 and 2. |
| `simulate_representative_networks.m` | Simulate the three networks and plot their activity. |
| `generate_scan_networks.m` | Generate 6,000 networks: 60 α values from 0.1 to 5, with 100 realisations each. |
| `compute_fig1c.m` | Simulate the scan networks and calculate the duration curve in Figure 1c. |
| `neuron_coordinates.mat` | Neuron positions and identifiers from FlyWire v783. |

## Run

Keep all files in the same directory. Open that directory in MATLAB and run:

```matlab
generate_representative_networks;
simulate_representative_networks;
generate_scan_networks;
compute_fig1c;
```

Results are saved in `results/`. Tested with MATLAB R2026a. The full scan can be resumed by rerunning `compute_fig1c`; generate each network file once.

## Data source

The coordinate file retains the first recorded position per neuron, with original row order and no spatial transformation. FlyWire v783 data are distributed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/); see the [FlyWire data-use guidelines](https://home.flywire.ai/guidelines).

Dorkenwald, S. et al. Neuronal wiring diagram of an adult brain. *Nature* **634**, 124–138 (2024). [doi:10.1038/s41586-024-07558-y](https://doi.org/10.1038/s41586-024-07558-y).

**This repository provides the code for Figure 1. All other results in the article can be obtained from the generated networks and simulation outputs using the [Brain Connectivity Toolbox (BCT)](https://sites.google.com/site/bctnet/) together with the other calculations and analyses described in the article.**
