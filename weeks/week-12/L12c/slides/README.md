# L12c lecture slides

[PDF deck](CHEME-5800-L12c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L12c-Slides-Fall-2026.tex)

The 23-slide deck follows the [Deep Q-Learning lecture](../CHEME-5800-L12c-Lecture-DeepQLearning-Fall-2026.ipynb) in its order. It opens with the Q-table and its three problems, then defines Q-networks, the linear Q-network with radial basis features, and the deep Q-network. It then covers the DQN loss, the gradient step of a linear network, the two stabilizers, and the DQN algorithm. It closes with the example, overestimation and Double DQN, the lab, and the Summary. Its three learning objectives align with its three closing takeaways.

**Review status:** Built November 10, 2026; not yet reviewed by the instructor. A read-only codex review scored the deck 9/10 for accuracy and fidelity, found no equation or number that differs from the lecture or the example's saved outputs, and marked it ready for review. Its fixes were applied: $p$ is now defined on the two-networks slide, the transition tuple is glossed, the gradient is defined, the done-flag condition is back in the pseudocode, DQN is spelled out, the 41-level result says "within 100 cycles", and the lab bullet names what Task 3 measures. The deck was not re-scored after these fixes. Later on November 10, a review of the lecture and the example changed the lecture's wording, and the deck was synced to it: the first objective, the check against the table, the convergence conditions, the notes after the algorithm (including "the policy gives an action for any state"), and overestimation. At the instructor's request, the radial basis slide and the one-hot slide became one two-column slide, "Two Choices of Features", and the check against the table moved onto the gradient-step slide, without the Q-learning update equation or the comparison with logistic regression. The build has no overfull or underfull boxes.

The style files and Cornell seal are copied unchanged from L12a (identical to L10c, L10a, L9c, and L9a, which match the approved L6a deck). The deck keeps their 16:9 format, typography, palette, title page, and footer. Text, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L12c/` directory.

`make figures` builds the two figure PDFs in `assets/`, which the deck includes. The Q-table figure is the L12a lecture's SVG, which the L12c lecture also shows; `rsvg-convert` ignores its dark-mode style block and writes the light colors. The Q-networks figure is the light TikZ PDF in the [figure folder](../figs/Fig-Q-Networks/), copied unchanged. This requires `rsvg-convert`.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, and the lecture and example |
| 4–5 | The Q-table figure and its three problems: exponential growth, no generalization, and rounding |
| 6–7 | Q-networks: the definition, the greedy policy, and the two-networks figure |
| 8–9 | The linear Q-network and two choices of features: radial basis functions, and one-hot features, which make a Q-table a linear network |
| 10 | The deep Q-network |
| 11–12 | The DQN loss: bootstrap targets, transitions and the done flag, and the DQN Bellman Loss box |
| 13 | The gradient step of a linear network, with the check against the table |
| 14 | The two stabilizers: the replay buffer and the target network |
| 15–18 | The DQN algorithm: Initialize and hyperparameters, the episode loop, the training step, and the notes |
| 19 | Example: a linear DQN for adaptive drug dosing |
| 20–21 | Overestimation and Double DQN |
| 22 | Lab: overestimation and Double DQN |
| 23 | Summary with three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck follows the lecture's notation: the Q-network $Q(s,a;\theta)$ and the target network $\theta^{-}$, the action set $\mathcal A$ with $n$ actions, the feature vector $\phi(s)\in\mathbb R^{p}$, the weight vectors $\mathbf w_{a}$ and the weight matrix $\mathbf W$, the basis-function centers $\mathbf c_{j}$ and width $\sigma$, the transitions $(s_{i},a_{i},r_{i},s_{i}',d_{i})$ with done flag $d_{i}$, the targets $y_{i}$, the loss $\mathcal L(\theta)$, the learning rate $\alpha$, the discount factor $\gamma$, the replay buffer $\mathcal D$ of size $M$, the warm-up size $N_{\text{warm}}$, the mini-batch size $N_{\text{batch}}$, the copy interval $C$, the exploration probability $\epsilon$, the random number $\rho$, the number of episodes $N$, the step limit $t_{\max}$, and the counters $t$ and $\tau$.

The deck calls the L12b lab "the dosing lab", so that "the lab" always means the L12d lab. The algorithm is split over two slides, with the training step (step 2.5) on its own slide; its wording follows the lecture. The objectives and takeaways are shortened from the lecture's to fit the slide format; they make the same claims.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L12c-Lecture-DeepQLearning-Fall-2026.ipynb | `c2fc2148285ea7ac9fad79a64b2b73b2e42d8467804f23a7ed000c58bf935bde` |
| CHEME-5800-L12c-Example-LinearDQN-AdaptiveDosing-Fall-2026.ipynb | `aa4f9cad118540a7ca61af0309a1c84c4b96e8d2fce7e894f1468460b85075f8` |
| CHEME-5800-L12d-Lab-DoubleDQN-Fall-2026.ipynb | `f6341f051642d1d4410e167afd570c1fa381515d6d26843bc8388f8810ae56b3` |
