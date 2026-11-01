# L11c lecture slides

[PDF deck](CHEME-5800-L11c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L11c-Slides-Fall-2026.tex)

The 21-slide deck follows the [Markov Decision Processes lecture](../CHEME-5800-L11c-Lecture-MarkovDecisionProcesses-Fall-2026.ipynb) in its order: the lecture and example, from Markov chains to decisions, the five MDP components, the agent's goal, the grid world example, its layout figure, and grid worlds in chemical engineering, value iteration and the Bellman backup, the one-backup worked example over three slides (the figure, where 10 and 0 come from, and the two action values), the value iteration algorithm with policy extraction and its cost, then random rollout, its algorithm, and its cost and accuracy, the example, the lab, and the Summary. Three learning objectives align with three closing takeaways.

**Review status:** Built October 26, 2026; not yet reviewed by the instructor. A read-only codex review scored the first build 8.1/10, recomputed the worked backup (7.4, −1.4, −1, 4.112, −1.432), and found the other equations faithful. Its main finding was applied: the random rollout pseudocode had dropped the lecture's `terminated` flag and While loop, and now keeps them. The policy slide's note on $\pi$ and the Summary no longer name another lecture or preview next week (the course rule of October 15), and the truncation-bound slide now defines $U^{\mathrm{random}}$ and $U_d^{\mathrm{random}}$. Its suggestion to narrow the continuous-state claim on the rollout cost slide was declined, because the deck states the lecture's claim. The deck was not re-scored after these fixes. The same day, a new example notebook comparing value iteration and random rollout was added, and the deck gained the lecture-and-example slide and an example slide. The build has no overfull or underfull boxes. On November 1, 2026, the deck was synced with the instructor's lecture edits: the terminal-state, convergence-properties, and older random-rollout material was removed, the layout slide now shows the layout figure, the backup figure and the note on 7.4 and 0 were added to the worked example, and a slide on grid worlds in chemical engineering was added.

The style files and Cornell seal are copied unchanged from L10c (identical to L10a, L9c, and L9a, which match the approved L6a deck). The deck keeps their 16:9 format, typography, palette, title page, and footer. Text, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L11c/` directory.

`make figures` rebuilds the grid world figures from their TikZ sources in the lecture's [figure folder](../figs/); the deck includes the resulting PDFs directly. This requires `pdflatex` and `pdf2svg`.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–4 | Title, three learning objectives, the lecture and example, and the move from Markov chains to decisions |
| 5–6 | The MDP tuple and its five components; the agent's goal, a policy that maximizes the discounted objective |
| 7–9 | The grid world example's components; its layout figure, rewards that depend only on the chosen action, and the terminal goal; grid worlds in chemical engineering |
| 10 | Value iteration, the Bellman backup, and $U^{*}$ |
| 11–13 | Worked example: the setup and the backup figure; where 10 and 0 come from; the two action values and $U_2(3,1)=6.02$ |
| 14–15 | The value iteration algorithm and policy extraction; its computational complexity |
| 16–18 | Random rollout; its algorithm; its computational complexity and accuracy |
| 19 | Example: random rollout in the lava grid world |
| 20 | Lab: value iteration in a grid world |
| 21 | Summary with three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck follows the lecture's notation: the tuple $(\mathcal S,\mathcal A,R(s,a),T(s'\,|\,s,a),\gamma)$, available actions $\mathcal A_s$, observed rewards $r$, the policy $\pi$, values $U_k$ and $U^{*}$, action values $Q_1(s,a)$, the tolerance $\epsilon$, the limit $k_{\max}$, and for random rollout the depth $d$, the number of rollouts $N$, the return $G$, the visit counts $n(s)$, and the estimate $\hat U(s)$.

Two additions are the deck's own. The policy slide notes that $\pi$, previously a state distribution, now denotes a policy. The value iteration algorithm's step 1 names the Bellman backup from the earlier slide rather than repeating the equation. The random rollout pseudocode keeps the lecture's `terminated` flag and While loop but combines the bullets within each step so the algorithm fits on one slide. The Summary's closing sentence restates the third takeaway; the lab slide gives no grid size or discount factor, since the lab sets those in code cells.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L11c-Lecture-MarkovDecisionProcesses-Fall-2026.ipynb | `a6802f8ac2f9021f621a002bf021ed64fb7b531ce3aaa719b6af600e5d3510f2` |
| CHEME-5800-L11c-Example-RandomRollout-Fall-2026.ipynb | `fa6c98467202405a9f4c47124f329ca0f021394e0de1350b654f0720ee42b96b` |
| CHEME-5800-L11d-Lab-ValueIterationGridWorld-Fall-2026.ipynb | `6d873576808aa765bf9fa0a78f2336984e65ce35156bf1a771bad268843eef36` |
