# Kunitz-family alignment

`PF00014-kunitz-alignment.fasta` is the cleaned 53-column Kunitz-domain alignment
used by the stochastic-attention protein-generation study. It contains 99 aligned
sequences. The optional protein-generator example retains the records containing
only the 20 standard amino acids; records containing alignment gaps or a
non-standard symbol remain in this source file for provenance and are reported as
excluded by the notebook.

- Source repository: <https://github.com/varnerlab/SA-Protein-Modeling-Study>
- Source path: `code/pfam-families/data/PF00014/stored_sequences.fasta`
- Source blob: `8d7a67cee31ced148ad375c0d7884cd15cc596ca`
- Retrieved: 2026-10-28
- Repository license: MIT
- Related paper: <https://arxiv.org/abs/2603.14717>

The weekly release vendors this small file so the example runs without network
access.
