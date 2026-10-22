# L10c lecture slides

[PDF deck](CHEME-5800-L10c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L10c-Slides-Fall-2026.tex)

The 20-slide deck follows the [Stochastic Multi-Armed Bandit Problems lecture](../CHEME-5800-L10c-Lecture-StochasticMultiarmBandits-Fall-2026.ipynb) in its order: exploration versus exploitation, the bandit arms figure and the applications table, the stochastic bandit model and regret, then explore-first, epsilon-greedy, and UCB1 with their regret bounds, the UCB1 worked example and its figure, and the comparison of the bounds; then the binary Bernoulli bandit with the Beta prior and posterior, epsilon-greedy and Thompson sampling for Bernoulli rewards, the Thompson sampling worked example and its posterior figure, the lab, and the Summary. Three learning objectives align with three closing takeaways.

**Review status:** Built October 21, 2026; not yet reviewed by the instructor. A read-only codex review scored the first build 8.5/10 and found it mathematically faithful: the theorem numbers, the UCB1 values (0.947, 1.697, 1.893), and the Thompson sampling example match the lecture. Its definition and density findings were applied: the bandit arms slide now explains $a_t$, $r_t$, $\mu^\star$, and $\Delta(1)$; the model slide defines $\mathcal D_a$; the Beta slide defines the prior and posterior in plain words; the explore-first slide names the natural logarithm and defines the sample mean; the epsilon-greedy bound moved to the comparison slide so the algorithm has room; both arg-max steps state the tie rule; the UCB1 example notes that a bound can exceed the largest possible reward; and each Summary takeaway is one line. The deck was not re-scored after these fixes.

A second pass the same day added a posterior figure to the Thompson sampling worked example, which had been a table, moved the Russo et al. (2020) sentence back to the algorithm slide as in the lecture, and rewrote the Summary takeaways, which the first pass had cut to bare labels, as short claims in the shape of the L6a Summary. A second read-only codex review scored this version 9/10 ("strong and teachable") and confirmed the figure's densities, means, and samples. Its three findings were applied: the figure was redrawn wider with larger lettering so its labels read at projection size, the epsilon-greedy and UCB1 initialization steps now name the first reward $r_a$, the pull count, and the sample mean, and the bandit arms caption now introduces the round $t$. The deck was not re-scored after these fixes. The build has no overfull or underfull boxes.

**Revised October 22, 2026** after a read-only codex review of both week 10 decks (8.7/10, no errors). The bandit arms and UCB1 example figures were redrawn with larger labels, as the Thompson figure had been, and given more of their slides' height, so their labels read at projection size; the lecture uses the same figures. The Thompson example's opening line and the second Summary takeaway are now full sentences, and the third takeaway states that the UCB1 bound grows more slowly than the other two. The lab slide now says the lab averages the regret over 30 games and compares how fast it grows with the bounds, after the lab's revision the same day.

The style files and Cornell seal are copied unchanged from L10a (identical to L9c and L9a, which match the approved L6a deck). The deck keeps their 16:9 format, typography, palette, title page, and footer. Text, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L10c/` directory.

`make figures` refreshes the bandit arms, UCB example, and Thompson sampling example figures in `assets/` from the lecture's [figure folder](../figs/), where the TikZ sources and their Makefiles live. The deck uses the light PDFs.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–2 | Title and three learning objectives |
| 3 | Exploration versus exploitation |
| 4–5 | The bandit arms figure; the applications table with one source per row |
| 6–7 | The stochastic bandit model and its assumptions; the regret $R(T)$, the cumulative gap loss $G(T)$, and $\mathbb E[R(T)]=\mathbb E[G(T)]$ |
| 8–9 | The explore-first algorithm; its regret bound, with "of order" and big-O defined |
| 10 | The epsilon-greedy algorithm with the capped $\epsilon_t$ |
| 11–13 | Optimism under uncertainty and the confidence radius; the UCB1 algorithm and its regret bound; the two-arm worked example and figure |
| 14 | Comparing the three regret bounds, with the epsilon-greedy theorem and the Slivkins theorem numbers |
| 15–16 | The binary Bernoulli bandit and the Beta prior and posterior; epsilon-greedy for Bernoulli rewards |
| 17–18 | The Thompson sampling algorithm, the Russo et al. (2020) comparison, and its 1933 origin; the worked example and its posterior figure |
| 19 | Lab: bandit algorithms |
| 20 | Summary with three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck follows the lecture's notation: arms $a\in\mathcal A$ with $|\mathcal A|=K$, rounds $t=1,\ldots,T$, mean rewards $\mu(a)$, the best mean $\mu^\star$, gaps $\Delta(a)$, sample means $\bar\mu(a)$, pull counts $N_a$, the exploration probability $\epsilon_t$, the confidence radius $U(a,t)$, success probabilities $\theta_a$, Beta parameters $\alpha(a)$ and $\beta(a)$, successes $S(a)$, failures $F(a)$, and posterior samples $p(a)$. The applications table's cells are shortened from the lecture's. The Thompson (1933) line, which the lecture places after the applications table, sits on the Thompson sampling slide. The Thompson sampling posterior figure was drawn for the deck; the lecture's worked example has no figure. The pseudocode keeps the lecture's Initialize, For, and numbered-step format with If/Otherwise branches; the explore-first and epsilon-greedy steps are condensed so each algorithm fits on one slide. The lecture has no example notebook, so there is no example slide.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L10c-Lecture-StochasticMultiarmBandits-Fall-2026.ipynb | `ff5db7840fe1e85bc94052b8a4387fe282299c1622ee2fc9e4b64ca0af96ef59` |
| CHEME-5800-L10d-Lab-BanditAlgorithms-Fall-2026.ipynb | `27ae78402068c1cc1abd34cae3eb72eaba426cf5ed11aa92d1bb87975d1a7a6d` |
