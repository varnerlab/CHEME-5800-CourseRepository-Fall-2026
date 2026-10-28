# L10c lecture slides

[PDF deck](CHEME-5800-L10c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L10c-Slides-Fall-2026.tex)

The 29-slide deck follows the [Stochastic Multi-Armed Bandit Problems lecture](../CHEME-5800-L10c-Lecture-StochasticMultiarmBandits-Fall-2026.ipynb) in its order: the lecture and example, exploration versus exploitation, the bandit arms figure and the applications table, the stochastic bandit model and regret, then explore-first, epsilon-greedy, and UCB1 with their regret bounds, the UCB1 worked example and its figure, the example, and the comparison of the bounds; then the binary Bernoulli bandit, how zeros and ones become a probability, the Beta prior and posterior, epsilon-greedy and Thompson sampling for Bernoulli rewards, the Thompson sampling worked example and its posterior figure, the lab, and the Summary. Three learning objectives align with three closing takeaways.

**Review status:** Built October 21, 2026; not yet reviewed by the instructor. A read-only codex review scored the first build 8.5/10 and found it mathematically faithful: the theorem numbers, the UCB1 values (0.947, 1.697, 1.893), and the Thompson sampling example match the lecture. Its definition and density findings were applied: the bandit arms slide now explains $a_t$, $r_t$, $\mu^\star$, and $\Delta(1)$; the model slide defines $\mathcal D_a$; the Beta slide defines the prior and posterior in plain words; the explore-first slide names the natural logarithm and defines the sample mean; the epsilon-greedy bound moved to the comparison slide so the algorithm has room; both arg-max steps state the tie rule; the UCB1 example notes that a bound can exceed the largest possible reward; and each Summary takeaway is one line. The deck was not re-scored after these fixes.

A second pass the same day added a posterior figure to the Thompson sampling worked example, which had been a table, moved the Russo et al. (2020) sentence back to the algorithm slide as in the lecture, and rewrote the Summary takeaways, which the first pass had cut to bare labels, as short claims in the shape of the L6a Summary. A second read-only codex review scored this version 9/10 ("strong and teachable") and confirmed the figure's densities, means, and samples. Its three findings were applied: the figure was redrawn wider with larger lettering so its labels read at projection size, the epsilon-greedy and UCB1 initialization steps now name the first reward $r_a$, the pull count, and the sample mean, and the bandit arms caption now introduces the round $t$. The deck was not re-scored after these fixes. The build has no overfull or underfull boxes.

**Revised October 22, 2026** after a read-only codex review of both week 10 decks (8.7/10, no errors). The bandit arms and UCB1 example figures were redrawn with larger labels, as the Thompson figure had been, and given more of their slides' height, so their labels read at projection size; the lecture uses the same figures. The Thompson example's opening line and the second Summary takeaway are now full sentences, and the third takeaway states that the UCB1 bound grows more slowly than the other two. The lab slide now says the lab averages the regret over 30 games and compares how fast it grows with the bounds, after the lab's revision the same day.

**Revised October 26, 2026** after mid-semester feedback. Three Discuss slides carry the lecture's new discussion prompts, and the applications table gained a reaction-conditions row (Wang et al., 2024) to match the lecture; the table is set one size smaller so the five rows fit.

**Revised October 27, 2026** for the new [UCB1 example](../CHEME-5800-L10c-Example-UCB1StepByStep-Fall-2026.ipynb). A Lecture and Example slide follows the objectives, a Discuss slide carries the lecture's new prompt at the end of the regret section, and an example slide follows the UCB1 worked example, where the lecture stops for the example. Later the same day, the instructor asked for the slides to follow the lecture's order and to hold 60 to 80 words each. The Bernoulli slide was split in three to match the lecture: the Bernoulli model, then a new slide on zero-one rewards (the indicator reward, why rewards are 0 and 1 rather than $\pm1$, and the sample mean as the fraction of successes), then the Beta prior and posterior. The applications table now spans two slides, with shorter cells, and every slide above 80 words was tightened. Discuss slides and the figure slides stay shorter. A final pass that day matched the lecture's edits: the rescaling line says arrival time rather than delay, both Discuss prompts were revised (the explore-first prompt lost its hint; the Thompson prompt asks which arms to keep testing), the lab slide no longer states the arm or game counts, the second takeaway names the four rules' ways of exploring, and the Summary closes on bandit feedback rather than Markov decision processes. A final clarity pass rewrote the explore-first bound slide in plain words, writing each bound as one big-O expression (the same bound, with the exponents inside the big-O) and defining big-O once; the same pass clarified the bandit arms caption, the rescaling line, the explore-first max and min, the confidence radius, the UCB1 example caption, the comparison paragraph, and the zero-one coding bullet, and the lecture received the same edits.

**Revised October 28, 2026** to match the lecture's rewritten Regret section. The regret slide now opens with regret as the reward an agent loses while it learns, notes that the agent can compute neither $R(T)$ nor $G(T)$, which we can compute only when we know the arm means, and labels the terms of $R(T)$ and $G(T)$ with underbraces, as the lecture does. The name "cumulative gap loss" is now "gap loss". The bandit arms figure gained a line naming what is hidden from the agent; the bandit arms slide picks it up from the figure folder, and its caption now matches the lecture: the agent sees only the blue dot, and the question is how to choose the pulls. The big-O definition was removed from the explore-first bound slide and the lecture, because students have used big-O since week 3.

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
| 1–3 | Title, three learning objectives, and the lecture and example |
| 4–5 | Exploration versus exploitation; Discuss: trying something new versus returning to a favorite |
| 6–8 | The bandit arms figure; the applications table, split over two slides, with one source per row, including reaction conditions, and the rescaling of arrival time and profit |
| 9–11 | The stochastic bandit model and its assumptions; the regret $R(T)$ and the gap loss $G(T)$, with their terms labeled, and $\mathbb E[R(T)]=\mathbb E[G(T)]$; Discuss: whether two algorithms that both end on the best arm lost the same reward |
| 12–13 | The explore-first algorithm; its regret bound |
| 14 | The epsilon-greedy algorithm with the capped $\epsilon_t$ |
| 15–18 | Optimism under uncertainty and the confidence radius; the UCB1 algorithm and its regret bound; the two-arm worked example and figure; Example: step through UCB1 |
| 19–20 | Comparing the three regret bounds, with the Slivkins theorem numbers; Discuss: when explore-first is the better choice |
| 21–24 | The binary Bernoulli bandit and the Bernoulli distribution; zero-one rewards as an indicator, and the sample mean as the fraction of successes; the Beta prior and posterior; epsilon-greedy for Bernoulli rewards |
| 25–27 | The Thompson sampling algorithm, the Russo et al. (2020) comparison, and its 1933 origin; the worked example and its posterior figure; Discuss: which reaction conditions to keep testing, and how the posteriors help decide |
| 28 | Lab: bandit algorithms |
| 29 | Summary with three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck follows the lecture's notation: arms $a\in\mathcal A$ with $|\mathcal A|=K$, rounds $t=1,\ldots,T$, mean rewards $\mu(a)$, the best mean $\mu^\star$, gaps $\Delta(a)$, sample means $\bar\mu(a)$, pull counts $N_a$, the exploration probability $\epsilon_t$, the confidence radius $U(a,t)$, success probabilities $\theta_a$, Beta parameters $\alpha(a)$ and $\beta(a)$, successes $S(a)$, failures $F(a)$, and posterior samples $p(a)$. The applications table's cells are shortened from the lecture's. The Thompson (1933) line, which the lecture places after the applications table, sits on the Thompson sampling slide. The Thompson sampling posterior figure was drawn for the deck; the lecture's worked example has no figure. The pseudocode keeps the lecture's Initialize, For, and numbered-step format with If/Otherwise branches; the explore-first and epsilon-greedy steps are condensed so each algorithm fits on one slide.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L10c-Lecture-StochasticMultiarmBandits-Fall-2026.ipynb | `0b1218d22cc7288d003489ee3e138ba9c317ecea4cb09e7a28e0a1e92d32db90` |
| CHEME-5800-L10c-Example-UCB1StepByStep-Fall-2026.ipynb | `a5e6de8f302eb5eca208f4141cccf65c50d982c5cf848a171b7be496b1b7c43d` |
| CHEME-5800-L10d-Lab-BanditAlgorithms-Fall-2026.ipynb | `66960d07c1caf5d2fd15c33839322799850e8898284910fb01b57d1589d68c46` |
