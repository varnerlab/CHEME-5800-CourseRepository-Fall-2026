# L12a lecture slides

[PDF deck](CHEME-5800-L12a-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L12a-Slides-Fall-2026.tex)

The 19-slide deck follows the [Model-Free Reinforcement Learning and Q-Learning lecture](../CHEME-5800-L12a-Lecture-QLearning-Fall-2026.ipynb) in its order. It opens with the reinforcement learning problem and moves from value iteration to the action values and the Q-table. It then covers the Q-learning update, its weighted-average form, the algorithm, the convergence conditions, and the practical caveats. It closes with the example, the lab, and the Summary. Its three learning objectives align with its three closing takeaways.

**Review status:** Built November 7, 2026; not yet reviewed by the instructor. A read-only codex review scored the first build 8.5/10 and checked the pseudocode line by line against the lecture. Its fixes were applied: the MDP tuple is now defined before the Bellman backup, $Q^{*}$ is introduced with $U^{*}$ rather than $U_k$, the objectives and the first takeaway no longer suggest that the agent learns without rewards, the example slide states its result for the start square $(20,20)$, and the sparse-reward bullet keeps its condition and reward shaping. The single-outcome bullet now names the lava grid world, because the L12d problem has random rewards. The lecture sentence was corrected the same way. Its suggestion to qualify "fluctuate around $Q^{*}$" for a possible bias was declined, because the deck states the lecture's claim. The deck was not re-scored after these fixes. The build has no overfull or underfull boxes.

The style files and Cornell seal are copied unchanged from L11c (identical to L10c, L10a, L9c, and L9a, which match the approved L6a deck). The deck keeps their 16:9 format, typography, palette, title page, and footer. Text, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L12a/` directory.

`make figures` converts the lecture's two SVG figures in the [figure folder](../figs/) to the PDFs in `assets/`, which the deck includes. The SVGs carry a dark-mode style block; `rsvg-convert` ignores it and writes the light colors. This requires `rsvg-convert`.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, and the lecture and example |
| 4–5 | The reinforcement learning problem, its agent and environment figure, and the earlier approaches to learning from interaction |
| 6 | From value iteration to action values: the Bellman backup and $Q^{*}(s,a)$ written in terms of $U^{*}(s)$ |
| 7 | The Q-table figure |
| 8 | What value iteration needs, and the Q-table as the agent's memory |
| 9–10 | The Q-learning update with its target, the weighted-average form, and the greedy policy |
| 11–13 | Episodes, the epsilon-greedy rule, and the link to bandits; the Q-learning algorithm; absorbing states |
| 14–15 | The convergence conditions and how to meet them |
| 16 | Caveats and practical notes |
| 17 | Example: Q-learning in the lava grid world |
| 18 | Lab: adaptive drug dosing with Q-learning |
| 19 | Summary with three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck follows the lecture's notation: the tuple $(\mathcal S,\mathcal A,R(s,a),T(s'\,|\,s,a),\gamma)$, the values $U_k$ and $U^{*}$, the action values $Q(s,a)$ and $Q^{*}(s,a)$, the observed reward $r$ and next state $s'$, the learning rate $\alpha$ and $\alpha_n(s,a)$, the exploration probability $\epsilon$, the policy $\pi$, the number of episodes $N$, the step limit $d$, and the step counter $t$.

The algorithm slide shortens the Given list to symbols defined on earlier slides so the algorithm fits on one slide. The objectives and takeaways are shortened from the lecture's to fit the slide format; they make the same claims.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L12a-Lecture-QLearning-Fall-2026.ipynb | `6a1987ef3c22ce535afb0eb826f4dc3d6c6e18eabade8725c69fc139d2b600d0` |
| CHEME-5800-L12a-Example-QLearningGridWorld-Fall-2026.ipynb | `fe99c46bc304268038922b2f8a389d49dc6675548cc4ac6b1c1a33edf8d265c5` |
| CHEME-5800-L12b-Lab-AdaptiveDosing-QLearning-Fall-2026.ipynb | `7695c4f1945f85ae1e89453dcc3d326b2d8588b78c8266a4a57b783b2b9fcbea` |
