# L3b data record

`reactor-runs.csv` contains eight instructor-generated synthetic reactor runs.
`reactor-metadata.json` records their origin, intended use, units, schema, and
constraints. The values are plausible only for classroom exercises and must not
be represented as experimental results.

`reactor-runs-invalid-example.csv` intentionally contains zero residence time and
a conversion above one. Its filename and location identify it as a known-bad data
example used to demonstrate validation failures.

## Authored-file checksums

```text
018dc9662e309456da77decc89274075385349cd25fd07e71b6ca789d86fdee3  reactor-runs.csv
2a4e7823a1d2001fe8bf3fc2ce1b70f77bb94d926edfdac979f0cd79aa350bc2  reactor-metadata.json
d2a474f71a98a19ca04068f6002e42c64b882e810fef3127f41a050816ec9a72  reactor-runs-invalid-example.csv
```

From this directory, verify the files with:

```bash
shasum -a 256 reactor-runs.csv reactor-metadata.json reactor-runs-invalid-example.csv
```
