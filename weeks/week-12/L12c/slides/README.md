# L12c lecture slides

[PDF deck](CHEME-5800-L12c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L12c-Slides-Fall-2026.tex)

The 22-slide deck follows the [Deep Q-Learning lecture](../CHEME-5800-L12c-Lecture-DeepQLearning-Fall-2026.ipynb) in its order. It opens with the Q-table and its three problems, then defines the Q-network $Q_\theta:\mathcal{S}\times\mathcal{A}\rightarrow\mathbb{R}$, the linear Q-network with two choices of features, and the feedforward deep Q-network. It then covers the DQN loss, the derivation and update of the linear gradient step, the replay buffer and the target network, and the DQN algorithm. It closes with the example and the Summary. Its three learning objectives align with its three closing takeaways.

**Review status:** Synced to the lecture on November 11, 2026, after the instructor's line-by-line review of the lecture. The deck now uses the $Q_\theta$ and $Q_{\mathbf{W}}$ notation; the new learning objectives; the grid-world examples of the Q-table's problems; "training estimates only the weights" for both networks; the feedforward network description; the annotated three-step gradient derivation; and the replay buffer and target network as what each is and why we need it. Removed with the lecture: the check against the table, regression and bootstrap targets, and the demo counts (36 basis functions, 148 weights, 3,000 episodes). At the instructor's request, the Overestimation subsection, Double DQN, and the Lab section were removed from the lecture and the deck, because the L12d lab will change. The figure copy in `assets/` was refreshed from the updated Q-networks figure. The build has no overfull or underfull boxes. Not yet reviewed by the instructor.

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
| 6–7 | Q-networks: the definition $Q_\theta:\mathcal{S}\times\mathcal{A}\rightarrow\mathbb{R}$, the greedy policy, and the two-networks figure |
| 8–9 | The linear Q-network and two choices of features: radial basis functions, and one-hot features, which make a Q-table a linear network |
| 10 | The deep Q-network: a feedforward network with input, hidden, and output layers |
| 11–12 | The DQN loss: transitions, the done flag, gradient descent, and the DQN Bellman Loss box |
| 13–14 | The gradient of a linear network (three-step derivation) and the gradient step |
| 15–16 | The two stabilizers: the replay buffer and the target network |
| 17–20 | The DQN algorithm: Initialize and hyperparameters, the episode loop, the training step, and the notes |
| 21 | Example: a linear DQN for adaptive drug dosing |
| 22 | Summary: three key takeaways |

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
