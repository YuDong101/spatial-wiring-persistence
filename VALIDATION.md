# Release validation — 6 October 2026

Validated with MATLAB R2026a on Windows. Other MATLAB releases and operating
systems have not been exercised for this release. The input readers, tables,
random streams and simulator use base MATLAB functions with the JVM enabled.

## Unit tests

Executed:

```matlab
results = runtests('tests/test_public_package.m');
assertSuccess(results);
```

Observed result:

```text
GREEN passed=9 failed=0 incomplete=0 total=9
```

The tests cover exact alpha values, matched coordinate sampling and edge counts,
repeatability, RNG isolation, absence of self-loops, uniform-unit invariance,
MAT/CSV input, invalid input handling, and a silent-network simulation.

## Three-condition integration and relocation

All three 200-neuron, 2,000-edge conditions were run using a local,
user-owned copy of the external FlyWire coordinate input. No coordinate file
or resulting simulation file is included in this release.

The code was then copied into a separate directory. MATLAB's search path was
reset with `restoredefaultpath`, its working directory changed to the copy,
and only that package directory was added. Unit tests and all three simulations
were repeated with an explicit external coordinate path.

Observed result:

```text
ISOLATED_TESTS passed=9 failed=0
ISOLATED_REPLAY all_three_results_equal=1 rng_restored=1
```

Comparison used `isequal` on the complete per-condition `result` structures:
duration, every spike time and neuron index, post-cue rate, alpha and endpoint
flag. All three matched their first-run counterparts exactly on this machine.
This checks repeatability and package independence, not statistical agreement
between a three-network example and the manuscript ensemble.

## Dependencies and simulator preservation

`matlab.codetools.requiredFilesAndProducts` was run with the package on the
MATLAB path. It identified all six executable package files and only MATLAB:

```text
DEPENDENCY_SCAN package_files=6 external_project_files=0 products=MATLAB
```

The simulator's 76 nonempty executable lines were compared in order with the
manuscript simulator after removing comments. They were identical. Source and
packaged simulator hashes are in `PROVENANCE.md`.

Tests use generated fixtures, never embedded FlyWire data. The release contains
source, documentation and hashes only. Production outputs are created by users
when they run the package with their coordinate input.
