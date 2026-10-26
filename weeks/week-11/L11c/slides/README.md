# L11c lecture slides

[PDF deck](CHEME-5800-L11c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L11c-Slides-Fall-2026.tex)

The 20-slide deck follows the [Markov Decision Processes lecture](../CHEME-5800-L11c-Lecture-MarkovDecisionProcesses-Fall-2026.ipynb) in its order: the lecture and example, from Markov chains to decisions, the five MDP components, the policy and terminal states, the grid world example and its figure, value iteration and the Bellman backup, the one-backup worked example over two slides, the value iteration algorithm with policy extraction and its cost, then random rollout, its algorithm, what it estimates with the truncation bound, and its cost and accuracy, the example, the lab, and the Summary. Three learning objectives align with three closing takeaways.

**Review status:** Built October 26, 2026; not yet reviewed by the instructor. A read-only codex review scored the first build 8.1/10, recomputed the worked backup (7.4, −1.4, −1, 4.112, −1.432), and found the other equations faithful. Its main finding was applied: the random rollout pseudocode had dropped the lecture's `terminated` flag and While loop, and now keeps them. The policy slide's note on $\pi$ and the Summary no longer name another lecture or preview next week (the course rule of October 15), and the truncation-bound slide now defines $U^{\mathrm{random}}$ and $U_d^{\mathrm{random}}$. Its suggestion to narrow the continuous-state claim on the rollout cost slide was declined, because the deck states the lecture's claim. The deck was not re-scored after these fixes. The same day, a new example notebook comparing value iteration and random rollout was added, and the deck gained the lecture-and-example slide and an example slide. The build has no overfull or underfull boxes.

The style files and Cornell seal are copied unchanged from L10c (identical to L10a, L9c, and L9a, which match the approved L6a deck). The deck keeps their 16:9 format, typography, palette, title page, and footer. Text, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L11c/` directory.

`make figures` refreshes the grid world figure in `assets/` from the lecture's [figure folder](../figs/) with `rsvg-convert` (librsvg), which ignores the SVG's dark-mode style block and writes the light colors. As in the L10a deck, the rule adds `xml:space="preserve"` to the SVG's text on the way in. The notebook SVG is unchanged.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–4 | Title, three learning objectives, the lecture and example, and the introduction's move from Markov chains to decisions |
| 5–6 | The MDP tuple and its five components; the policy, the discounted objective, terminal states, and the two algorithms |
| 7–8 | The grid world example's components; its figure, the expected reward, and the terminal goal |
| 9 | Value iteration, the Bellman backup, and $U^{*}$ |
| 10–11 | Worked example: the first-sweep values; the two action values and $U_2(3,1)=4.112$ |
| 12–13 | The value iteration algorithm and policy extraction; its computational complexity |
| 14–15 | Random rollout compared with value iteration; its algorithm |
| 16–17 | What a rollout estimates and the truncation bound; its computational complexity and accuracy |
| 18 | Example: value iteration and random rollout in the slippery grid world |
| 19 | Lab: value iteration in a grid world |
| 20 | Summary with three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck follows the lecture's notation: the tuple $(\mathcal S,\mathcal A,R(s,a),T(s'\,|\,s,a),\gamma)$, available actions $\mathcal A_s$, observed rewards $r$, the policy $\pi$, values $U_k$ and $U^{*}$, action values $Q_1(s,a)$, the tolerance $\epsilon$, the limit $k_{\max}$, and for random rollout the depth $d$, the number of rollouts $N$, the return $G$, the visit counts $n(s)$, the estimate $\hat U(s)$, and the bound $r_{\max}$.

Three additions are the deck's own. The policy slide notes that $\pi$, previously a state distribution, now denotes a policy. The worked example writes out the $0.8(+10)+0.1(-5)+0.1(-1)=7.4$ sum that the lecture describes in words. The value iteration algorithm's step 1 names the Bellman backup from the earlier slide rather than repeating the equation. The random rollout pseudocode keeps the lecture's `terminated` flag and While loop but combines the bullets within each step so the algorithm fits on one slide. The Summary's closing sentence restates the third takeaway; the lab slide gives no grid size or discount factor, since the lab sets those in code cells.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L11c-Lecture-MarkovDecisionProcesses-Fall-2026.ipynb | `c010aabe6991f1b04cd3375f9d430a166c5eae0c7a760f7bf93b5a594af9e630` |
| CHEME-5800-L11c-Example-RandomRollout-Fall-2026.ipynb | `d469b99cb15f191a84dffdaecd16bedb162b2f0eec13e754496e07fdf8014ecc` |
| CHEME-5800-L11d-Lab-ValueIterationGridWorld-Fall-2026.ipynb | `6d873576808aa765bf9fa0a78f2336984e65ce35156bf1a771bad268843eef36` |
