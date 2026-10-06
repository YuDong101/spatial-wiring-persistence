# Code and parameter provenance

- Scope approved for this release: three exact alpha values, 0.1 / 0.9 / 2;
  one simulation per value; external coordinate input; no distributed data.
- `+wmrep/trial.m` is the manuscript project's `trial.m` with comments and
  commented-out plotting/debugging fragments removed. The 76 nonempty
  executable lines were checked in order against the original.
- Original simulator SHA-256:
  `2DDBBE49717326F9E7579DEC36E3D0EC4CE15334F3BB99193EA4749F93F2D997`.
- Packaged simulator SHA-256:
  `761F78AC68E08001012FF908823DB224C6570C9775A4E698D52D6DC0F19509FC`.
- The coordinate-only network generator implements the manuscript Methods:
  directed distance-weighted draws without replacement, with matched coordinates
  and edge count. The generic degree-corrected Eq. 5 generator is not bundled.
- The fixed 2,000-edge demo budget and explicit new seeds are release settings.
  They do not reconstruct the original ensemble's per-realisation edge budgets.
- Parameter values and the endpoint definition follow the manuscript's current
  evidence definitions. The maximum trajectory is 5,000 ms; the cue ends at
  1,000 ms; confirmation requires a complete 100-ms silent window.
- FlyWire coordinate data and anatomical-background assets are external to this
  package. Their provenance is described in the README and the paper's Data
  availability statement. No third-party toolbox or dataset is included.

`FILES.sha256` records the release files. A simulation additionally records the
hashes of its input coordinate file and the six executable package files in
`networks.mat`. These identities permit checks without relying on an absolute
path on the original author's computer.
