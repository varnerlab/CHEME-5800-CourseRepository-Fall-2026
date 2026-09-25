# Central metabolism teaching figure

An original TikZ layout illustrating selected shared precursor pools and carbon
routes. It is a simplified teaching overview, not a tracing of KEGG's global map
and not an organism-specific reconstruction or a stoichiometric reaction model.

## Rebuild and reuse

Run `python build.py` here. Requirements: Python 3, `pdflatex` with TikZ,
`standalone` and Helvetica fonts, and `pdf2svg`.

- `Fig-Central-Metabolism.tex`: editable master, with named metabolites and routes.
- `Fig-Central-Metabolism.svg`: transparent canvas; automatic light/dark palette.
- `Fig-Central-Metabolism-light.svg`: fixed light palette for slides and editors.
- `Fig-Central-Metabolism-dark.svg`: fixed dark palette for a dark slide background.
- `Fig-Central-Metabolism.pdf`: light vector PDF for LaTeX manuscripts and print.
- `Fig-Central-Metabolism-dark.pdf`: dark vector PDF with a dark background.

SVG text is exported as vector glyphs so the fonts travel with the figure. Edit
labels in the TikZ source and rebuild; they are not editable SVG text objects.
Use the automatic SVG in the course's `course-diagram` image block so the notebook
theme propagates into the image. Its light palette remains active for printing.
Fixed dark SVGs have a transparent canvas and assume a dark host background.

## Scientific scope and references

Arrows show selected carbon-flow directions and may combine multiple reactions.
They are not assertions that every step is irreversible. Selected energy and redox cofactors are now shown: ATP investment and payoff
in glycolysis, NADH regeneration during lactate fermentation, oxidative pentose
phosphate NADPH production, pyruvate oxidation, and per-turn TCA outputs.
The TCA cycle includes all eight intermediates on a geometrically circular route.
The respiration inset connects reduced carriers to electron transport, a proton
gradient, and ATP synthase. Complete cofactor and proton balances, compartments,
alternative pathways, and TCA replenishment reactions remain omitted. The drawing cannot be
used directly as the reaction list for a mass-balanced FBA model. Glutamate is
one example of an amino acid feeding protein synthesis; it does not supply all
protein carbon. Fatty acids and ribose likewise provide only part of the inputs
to lipids and nucleotides. The routes illustrate general biochemistry and are
not all present in every organism.

Counts for glycolysis and pyruvate oxidation assume one glucose follows that
pathway completely. TCA counts are per acetyl-CoA. The two pyruvate branches are
alternative routes, not simultaneous full yields from the same glucose. Pentose
phosphate NADPH output is per glucose 6-phosphate entering the oxidative phase.
The label FADH2 uses the conventional reducing-equivalent bookkeeping: the FAD
at succinate dehydrogenase is enzyme-bound, and electrons reach the respiratory
chain through ubiquinone. The diagram does not imply a free FADH2 shuttle.

Biochemical reference maps consulted September 24, 2026:

- [KEGG carbon metabolism, map01200](https://www.kegg.jp/pathway/map01200)
- [KEGG glycolysis, map00010](https://www.kegg.jp/pathway/map00010)
- [KEGG TCA cycle, map00020](https://www.kegg.jp/pathway/map00020)
- [KEGG pentose phosphate pathway, map00030](https://www.kegg.jp/pathway/map00030)
- [OpenStax Biology 2e: Glycolysis](https://openstax.org/books/biology-2e/pages/7-2-glycolysis)
- [Molecular Biology of the Cell: How Cells Obtain Energy from Food](https://www.ncbi.nlm.nih.gov/books/NBK26882/)

Suggested caption: **Selected connections in central metabolism.** Glycolysis
supplies pyruvate and acetyl-CoA; branch routes supply pentose sugars,
fermentation products, and biomass precursors. The TCA cycle connects carbon
oxidation to biosynthesis. Selected ATP and redox-carrier yields distinguish carbon flow from energy
production. Arrows may summarize multiple reactions; complete stoichiometry,
compartments, and alternative routes are omitted.
