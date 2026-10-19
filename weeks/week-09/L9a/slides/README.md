# L9a lecture slides

[PDF deck](CHEME-5800-L9a-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L9a-Slides-Fall-2026.tex)

The 16-slide deck follows the [Linear Models for Classification lecture](../CHEME-5800-L9a-Lecture-LinearClassificationAndPerceptron-Fall-2026.ipynb) in its order: the binary classification problem and the linearly separable schematic, the Perceptron classifier, its decision boundary and mistake condition, online Perceptron training, why the update helps, the convergence theorem and what happens on data that are not separable, then the confusion matrix and the four performance metrics, the banknote example, the XOR lab, and the Summary. Three learning objectives align with three closing takeaways.

**Review status:** Built October 19, 2026; not yet reviewed by the instructor. A read-only codex review found no mathematical or factual errors. It flagged four references to other sessions by number or schedule (“We develop it in L9c”, “Later this week”, “In L9b”, “In L9c”), which the October 15 style-guide rule prohibits in slides; all were rewritten by content. Its suggested rewording of the Summary's convergence takeaway was adopted. The build has no overfull or underfull boxes.

**October 19 revision:** The example and the XOR lab now use the pocket algorithm (Gallant, 1990), which the course package's `learn(...)` runs with `pocket = true`: it keeps the parameters with the fewest training mistakes instead of the parameters from the last update. The example slide (14) now names it in the training task, and the lab slide (15) says the lab compares the boundaries and test performance with and without it. Both edits keep the build free of overfull and underfull boxes.

The style files and Cornell seal are copied unchanged from L7c (identical to L7a and L6c, which match the approved L6a deck). The deck keeps their 16:9 format, typography, palette, title page, and footer. Text, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L9a/` directory.

`make figures` refreshes the linearly separable schematic in `assets/` from the lecture's [SVG figure](../figs/Fig-LinearlySeparable-Schematic.svg). The lecture has no PDF or TikZ source for this figure, so the rule converts the SVG with `rsvg-convert` (librsvg), which ignores the SVG's dark-mode style block and writes the light colors.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, lecture and example links |
| 4–5 | Binary classification, the two strategies (Perceptron and logistic regression), and the linearly separable schematic with a two-sentence caption |
| 6–7 | The Perceptron classifier and sign function; the decision boundary, the mistake condition, and linear separability |
| 8–9 | Online Perceptron training pseudocode, and why each update moves a mistake toward the correct sign |
| 10–11 | Novikoff's convergence theorem, and stopping on separable and non-separable data, with the pointer to training by numerical optimization |
| 12–13 | Confusion matrix with the medical-diagnosis reading, and the four performance metrics with the rare-class warning |
| 14 | Banknote example: train (classical and pocket), test, and confusion matrix |
| 15 | Lab: the Perceptron on XOR, with and without the pocket algorithm |
| 16 | Summary with three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck follows the lecture's notation: augmented features $\hat{\mathbf x}_i$, parameters $\theta=(w_1,\ldots,w_m,b)$ with $p=m+1$, labels $y\in\{-1,1\}$, and the sign function in typewriter type. The Greek vector $\theta$ is set plain, as the notebook renders it. The performance metrics appear as a table with each metric's formula and a short statement of what it measures, rather than the lecture's bulleted questions, so the four fractions fit on one slide. The example slide summarizes the example's three tasks and its error-analysis callout.

The lecture (kernel-version metadata only) and the example notebook had uncommitted edits in the working tree when the deck was built; their hashes below are of those working copies. The example hash also reflects two later example changes: the dataset cell shows a `pretty_table` preview, because VS Code rendered the raw DataFrame's LaTeX output, which KaTeX cannot parse; and Task 1 adds the pocket algorithm (pseudocode, a `pocket = true` training run, and a comparison of training mistakes), which the example slide now mentions.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L9a-Lecture-LinearClassificationAndPerceptron-Fall-2026.ipynb | `3095d7c1b308e7b83b7cf2006f7c7dab41f187bedcfefc6718dda9fc2b4d9dba` |
| CHEME-5800-L9a-Example-LinearModels-Classification-Perceptron-Fall-2026.ipynb | `20b7d1ad019377b7d76e75111fb4103d9e06f515ca4340ac7b462f66c35fb70c` |
| CHEME-5800-L9b-Lab-XOR-Fall-2026.ipynb | `cf4a0312a5df462a41c4485db9429c4081c27450a8b242a27d96b3e4576d99ef` |
