# L9c lecture slides

[PDF deck](CHEME-5800-L9c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L9c-Slides-Fall-2026.tex)

The 25-slide deck follows the [Logistic Regression and Numerical Optimization lecture](../CHEME-5800-L9c-Lecture-LogisticRegressionAndOptimization-Fall-2026.ipynb) in its order: the logistic function figure, the Boltzmann derivation of the logistic model, the inverse temperature, and the move from probabilities to class labels; maximum likelihood and the cross-entropy loss, the gradient descent figure, the gradient of the loss, the gradient descent algorithm, convexity, and how well gradient descent works; regularization; constrained problems, penalty and barrier terms, and simulated annealing with the figure of an escape from a local minimum, its algorithm, and its temperature schedule; then the example, the banknote lab, and the Summary. Three learning objectives align with three closing takeaways.

**Review status:** Built October 19, 2026; not yet reviewed by the instructor. A read-only codex review found an undefined $m$ and $p$ (slide 4), “decrease both weights” for $\mu$ and $\rho$ although the penalty weight $1/(2\rho)$ grows (slide 17), and a Summary line that overstated simulated annealing (“uphill moves escape local minima”, now “can escape”). It also flagged references to other sessions (“In L9d”, “the L9a example”, “Next week”), which the October 15 style-guide rule prohibits in slides; all were rewritten by content. Two wording suggestions were adopted: the gradient step adds each $y_i\hat{\mathbf x}_i$ rather than moving toward it, and strong convexity shrinks the gap to the minimum loss. All were fixed. The build has no overfull or underfull boxes.

**October 19 revision:** A second review pass tightened wording on about ten slides, defined $p_\circ$ as the probability of accepting an average uphill move, rewrote the Summary takeaways in the retrospective voice, and added the simulated annealing figure (slide 19), which the lecture now shows in its Simulated Annealing section. No slide restates a value set in a code cell; the example slide (23) no longer gives the cluster centers, which the example's code sets. The lab slide (24) now says the lab compares logistic regression with the classical and pocket Perceptron, after the pocket algorithm was added to the banknote lab.

The style files and Cornell seal are copied unchanged from L7c (identical to L7a and L6c, which match the approved L6a deck). The deck keeps their 16:9 format, typography, palette, title page, and footer. Text, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L9c/` directory.

`make figures` refreshes the logistic function, gradient descent, and simulated annealing figures in `assets/` from the lecture's [figure folder](../figs/), where the TikZ sources and their Makefiles live. The deck uses the light PDFs.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, lecture and example links |
| 4–6 | Logistic function figure beside the move from the sign function to a probability; Boltzmann distribution and linear energy; the derivation, the two cases, and the boxed logistic model |
| 7–8 | The inverse temperature $\beta$, and from probabilities to class labels with a threshold |
| 9 | Likelihood, log-likelihood, and the boxed cross-entropy loss |
| 10–12 | Gradient descent and local minima figure; the gradient of the loss and its comparison with the Perceptron update; the gradient descent algorithm |
| 13–14 | Convexity, then the safe learning rate $1/L$, the $1/k$ rate, and the separable case, with a link to the advanced notebook |
| 15 | Regularized loss, strong convexity, and the practical notes on scaling and cross-validation |
| 16–17 | The constrained problem, with a link to the advanced notebook, and penalty and barrier terms |
| 18–19 | Simulated annealing, and the figure of simulated annealing escaping the local minimum $\theta_2$ |
| 20–22 | The simulated annealing setup and loop, and the sample-and-set and $K$ heuristics |
| 23 | Example: gradient descent and simulated annealing on two overlapping clusters |
| 24 | Lab: logistic regression on the banknotes, compared with the classical and pocket Perceptron |
| 25 | Summary with three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck follows the lecture's notation: augmented features $\hat{\mathbf x}_i$, parameters $\theta=(w_1,\ldots,w_m,b)$, labels $y\in\{-1,1\}$, inverse temperature $\beta$, the cross-entropy loss $J(\theta)$, the regularization parameter $\delta$, and the augmented objective $P_{\mu,\rho}(x)$. The Greek vector $\theta$ is set plain, as the notebook renders it and as the figures label it. The lecture's algebra from the Boltzmann distribution to the logistic function is shortened to its first and last lines; the two cases and the boxed result are kept. The simulated annealing pseudocode is split across a setup slide and a loop slide so it stays legible. The advanced nonlinear optimization notebook is linked from the two slides where the lecture points to it; it has no slides of its own.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L9c-Lecture-LogisticRegressionAndOptimization-Fall-2026.ipynb | `616e57011791a13df5bf4cac4cac7e582b26280d002f5a7174829c7e9112da8a` |
| CHEME-5800-L9c-Example-LogisticRegression-GD-SA-Fall-2026.ipynb | `0ac1755147c902a0d61a789f9894aa6676b01d01958770b351d6d840a2b155b0` |
| CHEME-5800-L9c-Advanced-NonlinearOptimization-Fall-2026.ipynb | `59c7918ff0ea6f1893ef8510938820499c619893a299690fb8a8897153819ad0` |
| CHEME-5800-L9d-Lab-LogisticRegression-Banknotes-Fall-2026.ipynb | `c090063022d003c345247c7acb0c226b0998a46b86c0af6b8739409616ff8496` |
