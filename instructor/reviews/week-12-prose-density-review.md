# Week 12 prose density review (2026-11-06)

Checked against the prose density rule added in 787080c (CLAUDE.md, AGENTS.md).
Nothing was edited. Cell numbers are 0-based notebook indices. The section name
and opening words are there so you can find each one.

**Renamed after this review (2026-11-06).** The dosing and grid world notebooks
swapped places, so the two sections below that name them use the old names and
the old cell numbers:

- The "L12a example" section is now the L12b lab,
  `L12b/CHEME-5800-L12b-Lab-AdaptiveDosing-QLearning-Fall-2026.ipynb`. Task 3 gained the
  update, the pseudocode, the TODO list, and the check, so cells from Task 3 on moved down.
- The "L12b lab" section is now the L12a example,
  `L12a/CHEME-5800-L12a-Example-QLearningGridWorld-Fall-2026.ipynb`. The two "Things to
  think about" cells were removed, so cells from Task 2 on moved up.

Find a row by its section name and opening words, not by its cell number.

Tags:

- **Length**: more than 3 sentences or more than about 60 words.
- **Chain**: a clause joined by ", so", "so that", "and so", a semicolon, or "and with it".
- **Multi**: one sentence carrying two or more ideas, usually joined by ", and" or ", which".
- **Restate**: says again what the same paragraph or a nearby one already said.
- **Qualifier**: a word or phrase that adds no information ("exactly", "actually", "at all").
- **Jargon**: a term the notebook uses without defining it.
- **Fragment**: bullets that are not full sentences.

Exempt and not listed: display equations, tables, pseudocode blocks, the
`Include` box, Julia signatures in docstrings, and the semicolons that separate
answer choices in `{yes, by a shortest path; yes, by a longer path; or no}`
(L12b cells 21 and 36). Change the answer sets too if you want zero semicolons.

## Status (2026-11-06, uncommitted)

- **Fixed:** every row tagged Length or Chain, except the four left on purpose below.
  The worst blocks were done first, then L12a (24 edits), L12b (15), L12c (10), and
  L12d (14), plus four follow-up fixes from codex. Codex scored L12a 10/10 and
  L12b to L12d 9.5/10, and the suite passes 240/240.
- **Left on purpose:**
  - L12a lecture cell 3, "where $Q^{*}(s,a)$ ...": 61 words.
  - L12a lecture cell 8, the sparse rewards bullet: 63 words.
  - L12a lecture cell 10, takeaways 2 and 3: 63 and 66 words, held to the house
    two-sentence form.
  - The semicolons that separate answer choices in the L12b predictions.
- **Open for your hand edit:** the rows tagged only Multi, Restate, Qualifier,
  Jargon, or Fragment.

## Worst blocks (fix these first)

**Status, 2026-11-06:** all eleven are rewritten (uncommitted). In L12a lecture
cell 5, the "Why does this update make sense?" paragraph was rewritten with the
temporal difference error paragraph, because one sentence ran across both. Every
other row in the tables below is still open.

| Words | Sentences | Where | Starts with |
|---|---|---|---|
| 132 | 5 | README paragraph 1 | "Week 12 learns a policy from experience" |
| 125 | 5 | L12a lecture cell 5 | "is the __temporal difference error__" |
| 114 | 3 | L12c cell 11 | "__Overestimation:__" bullet |
| 104 | 5 | L12d cell 0 | "__Background:__ A __bioreactor__" |
| 91 | 2 | L12c cell 11 | "The usual answer to the size of the table" |
| 87 | 4 | L12a lecture cell 7 | "A constant learning rate violates" |
| 86 | 2 | L12d cell 5 | "where $\mu_{\max}$ is the largest growth rate" |
| 83 | 3 | L12b cell 36 | "__What do we see?__ The learned policy takes" |
| 81 | 5 | L12c cell 7 | "For $\gamma$ near one" |
| 75 | 6 | L12d cell 28 | "__Question:__ Set `episodes_new = 2_000`" |
| 75 | 5 | L12b cell 23 | "We check our version on a small problem" |

## L12a lecture (`CHEME-5800-L12a-Lecture-QLearning-Fall-2026.ipynb`)

| Cell | Section | Starts with | Problem |
|---|---|---|---|
| 0 | title | "In this lecture, we explore the fundamentals" | Multi: one 45-word sentence carries the topic, a definition of RL, and "no model". "the fundamentals of" adds nothing. |
| 0 | objectives | LO 2 "Q-learning stores the value of every action" | Multi: "stores a table, and after each step it corrects one entry" is two ideas. |
| 0 | title | "At its core, reinforcement learning is about learning from doing" | Restate: repeats the opening sentence and LO 1. "At its core" is filler. |
| 1 | Examples | "[▶ Learn an adaptive drug-dosing policy" | Length: 67 words. The colon clause in sentence 2 is a second idea. |
| 2 | RL Problem | "Suppose we have an agent that can be" | Qualifier: "best possible" and "over time" add nothing. |
| 2 | RL Problem | "__Agent and environment.__ The agent observes" | Chain: semicolon. |
| 2 | RL Problem | "__Multiplicative weights__ adjusts" bullet | Chain + Multi: one 43-word sentence with four ideas, ending "; i.e., it minimizes regret". "in a principled way" is a qualifier. |
| 2 | RL Problem | "__Q-learning__ adds the state." | Multi: ", which lets the agent learn good behavior" is a second idea. "fundamental challenge": the "fundamental" adds nothing. |
| 3 | Value Iteration to Action Values | "Before we develop Q-learning, let's review" | Multi: one sentence that reviews, defines the MDP tuple, and previews "where value iteration uses its model". "exactly" is a qualifier. |
| 3 | same | "Value iteration computes the __optimal value function__" | Qualifier: "(utility, satisfaction, etc.)" is vague. |
| 3 | same | "where $k$ counts the __sweeps__" | Multi: the sweep definition and the convergence claim share one sentence. |
| 3 | same | "where $Q^{*}(s,a)$ is the expected cumulative" | Length: 61 words. The middle sentence joins $U^{*}=\max Q^{*}$ and $\pi^{*}=\arg\max Q^{*}$ with "and". |
| 3 | same | "Each of these equations needs the reward function" | Qualifier: "at all". |
| 4 | Q-table caption | "__The Q-table.__ Entry $(i,j)$ holds" | Chain: semicolon. |
| 5 | Q-Learning | "Q-learning, introduced by Watkins (1989)" | Length: 63 words, 4 sentences. Restate: "conducting repeated experiments in the world" repeats "directly from experience". "(potentially)" is a qualifier. |
| 5 | same | "where $0<\alpha\leq{1}$ is the learning rate" | Chain + Restate: "Only the entry ... changes; every other entry keeps its value" says one thing twice. |
| 5 | same | "__Why does this update make sense?__" | Length + Chain: 65 words, "cannot compute the sum ..., so it uses". The last sentence runs into the equation. Qualifier: "actually" appears twice. |
| 5 | same | "is the __temporal difference error__" | Length: 125 words, 5 sentences, the longest block in the week. Four ideas: the TD error, the $\alpha$ step, the deterministic case ($\alpha=1$ is a Bellman backup), and the random case ($1/n$ averaging). Split at each. |
| 6 | Algorithm | "Q-learning runs in __episodes__." | Length: 70 words. Sentence 3 packs both branches of epsilon-greedy. |
| 6 | Algorithm | "An episode ends as soon as the agent enters" | Chain: ", so the agent never updates the rows". |
| 7 | Convergence | "__Finite, fixed MDP and discounting__" bullet | Chain: ", so $Q$ fits in a table". Multi: sentence 2 lists three conditions. |
| 7 | same | "__Learning rate decay__" bullet | Length + Chain: 74 words, 4 sentences, a semicolon, and "and with it", the exact phrase the rule names. |
| 7 | same | "__Infinite exploration__" bullet | Length + Chain: 66 words and a semicolon. Sentence 2 carries "together with ... because". |
| 7 | same | "A constant learning rate violates" | Length: 87 words, 4 sentences. Multi: sentence 2 has three ideas (keep responding, fluctuate, fluctuations shrink with $\alpha$). |
| 8 | Caveats | "The infinite-exploration condition is the difficult one" | Multi: two ideas. "again and again" is filler. |
| 8 | same | "__Exploration schedule__" bullet | Restate: "This is the exploration versus exploitation trade-off we met with bandits" repeats the last sentence of cell 2. |
| 8 | same | "__Sparse and delayed rewards__" bullet | Length: 63 words. |
| 8 | same | "__Rate of convergence__" bullet | Chain + Multi: ", so the number of experiments grows ..., and a problem with a known model is usually solved faster" puts three ideas in one sentence. |
| 10 | Summary | KT 1 "__Model-free learning needs only experience:__" | Restate: the second sentence repeats the no-model claim of the first. Qualifier: "actually". |
| 10 | Summary | KT 2 "__Q-learning corrects one action value per step:__" | Length: 63 words. Multi: the second sentence joins the update and the greedy policy. |
| 10 | Summary | KT 3 "__Convergence needs exploration and a shrinking learning rate:__" | Length: 66 words. Multi: the first sentence is about 45 words with three conditions. |
| 10 | Summary | "Reinforcement learning lets an agent learn good behavior" | Restate: repeats KT 1. |

## L12a example (`CHEME-5800-L12a-Example-AdaptiveDosing-QLearning-Fall-2026.ipynb`)

| Cell | Section | Starts with | Problem |
|---|---|---|---|
| 0 | title | "Chemotherapy treats cancer with drugs" | Length: 70 words, 4 sentences. Multi: the last sentence frames the MDP and states the learning goal. Keep the biology glosses and split them out. |
| 0 | objectives | LO 1 "The state of the patient is the size of the tumor" | Multi: the state and the action share one sentence. |
| 4 | Task 1 | "In this task, we describe the patient" | Length: 67 words, 4 sentences. Split after the lead sentence. |
| 5 | Task 1 | "The growth term is logistic" | Length + Chain: 65 words, "round it ..., so the set of states is finite". Sentence 3 starts a new topic (absorbing states). |
| 12 | Why a fixed dose fails | "No fixed dose cures the patient." | Multi: "With no dose or the low dose ..., and the medium and high doses ..." covers two cases in one sentence. |
| 13 | Task 2 | "In this task, we compute the optimal policy" | Chain ×2: "because ... computes them, so the optimal policy is our benchmark" and "single next state, so the Bellman backup needs no sum". |
| 18 | Task 2 | "The optimal policy cures the patient." | Length: 4 sentences. Multi: sentence 2 has two "which" clauses plus "and it finishes with". Restate: the last sentence repeats the cell 12 conclusion that the dose must change with the state. |
| 19 | Task 3 | "In this task, we suppose we do not know the dynamics." | Restate: "It never uses the function to look ahead" repeats "can only give a dose and observe". |
| 19 | Task 3 | "> __Training:__ Each episode starts" | Length: 69 words. Three settings that would read better as three bullets. |
| 19 | Task 3 | "The seed fixes the random numbers" | Chain: ", so training again with the same seed". |
| 23 | Task 3 | "The learned policy gives the same doses" | Chain: ", so the agent found the pulse-and-rest schedule". |
| 26 | Benchmark | "The two policies choose the same action" | Length: 67 words. Multi: the last sentence joins two separate causes with "and". |
| 33 | Visualize | "The tumor burden falls with each high dose" | Multi: the tumor and the toxicity share one sentence. |
| 34 | Summary | KT 1 "__A dose now changes the patient later:__" | Chain: ", so no fixed dose cures the patient". |
| 34 | Summary | KT 2 "__The optimal policy pulses and rests:__" | Chain: "rest cycles so the toxicity can clear". |
| 34 | Summary | "When we know the rules of a system" | Chain: semicolon. The L12c closer has the same shape. |

## L12b lab (`CHEME-5800-L12b-Lab-QLearningGridWorld-Fall-2026.ipynb`)

| Cell | Section | Starts with | Problem |
|---|---|---|---|
| 0 | title | "__Backstory:__ Previously, we guided the robot" | Length: 75 words. Multi: sentence 3 lists three jobs. |
| 3 | Setup | "Your Q-learning function goes in" | Chain: "by its qualified name, so that re-running the setup cell". Jargon: "qualified name" is not defined. |
| 4 | Task 1 | "> __Grid World Structure:__ The model holds:" | Fragment: all four bullets are fragments. |
| 6 | Task 1 | "Next we describe what each square is worth" | Multi: one sentence holds two objects, each with its own "which" clause. |
| 10 | world the robot cannot see | "[The `build_mdp(...)` function]" | Length: 65 words, 4 sentences. The four rewards fit as bullets. |
| 12 | same | "Value iteration reads $R$ and $T$ directly" | Length + Chain: 67 words, 4 sentences, "at random ..., so it takes a random number generator". |
| 14 | same | "The square to the left of $(20,20)$" | Chain + Multi: "is the lava pit, so this one move costs 1000 and would end its episode" is three ideas. |
| 21 | Implement Our Version | "> __Implementation tasks__" | Fragment: the three TODO bullets name a quantity but give no instruction. |
| 21 | Implement Our Version | "Our version returns a `NamedTuple`" | Chain: "seeded with `seed`, so a rerun gives the same result". |
| 23 | Check | "We check our version on a small problem" | Length: 75 words, 5 sentences. State 1, state 2, and the optimal values fit as bullets. |
| 24 | Check | "__One step by hand:__" bullet | Length + Chain: 65 words. "absorbing, so every episode starts in state 1, and we take one step" is three ideas. Sentences 2 and 3 each pack the greedy action, $\alpha$, $\gamma$, and the result. |
| 24 | Check | "__The optimal values:__" bullet | Chain: "certain, so with $\alpha=1$". |
| 24 | Check | "__Absorbing rows stay zero:__" bullet | Chain: "absorbing state, so the grid world rows". |
| 26 | Task 3 | "In this task, we compare the learned policy" | Chain: "knows $R$ and $T$, so it computes". |
| 32 | Visualize | "[The `follow_policy(...)` function] starts at a square" | Multi: one 47-word sentence holding the procedure, three stop conditions, and a ", which means" clause. |
| 36 | Visualize | "__What do we see?__ The learned policy takes" | Length + Chain: 83 words, "not the correct value, so the policy can be right". Multi: sentence 2 joins two findings. |
| 38 | Visualize | "__What do we see?__ After 200 episodes" | Length: 73 words. Multi: "and far from it the values still reflect" is a second idea. |
| 38 | Things to think about | "__Question:__ Set `episodes_new = 2000` and `ϵ_new = 0.0`" | Length + Chain: 68 words, 4 sentences, two ", so" clauses. |
| 38 | Things to think about | "__Question:__ Now set `ϵ_new = 1.0`" | Length + Chain: 4 sentences, two ", so" clauses. |
| 39 | Summary | KT 1 "__Q-learning needs only the moves the robot makes:__" | Multi: sentence 1 has a ", which a simulator returned" clause and a "without ..." clause. |
| 39 | Summary | KT 3 "__The amount of training decides how far the reward spreads:__" | Chain + Multi: "back by one square, so with too few episodes it never reached ... and the policy walked in a loop". |

## L12c lecture (`CHEME-5800-L12c-Lecture-ValueIterationVsQLearning-Fall-2026.ipynb`)

| Cell | Section | Starts with | Problem |
|---|---|---|---|
| 0 | objectives | LO 3 "A table with one entry per state and action" | Multi: table size and overestimation are unrelated ideas joined by "and". |
| 2 | Model-Based and Model-Free | "__Value iteration is model-based.__" bullet | Chain: "transition probability, so the method needs". |
| 5 | value iteration with samples | third bullet "It moves $Q(s,a)$ only a fraction" | Chain: ", so that over many visits". |
| 6 | Computational Cost | "Each sweep of value iteration evaluates" | Chain: ", so a sweep costs". |
| 6 | same | "The number of sweeps depends on the discount factor." | Length + Chain: 64 words, 4 sentences, "factor of $\gamma$, so after $k$ sweeps". |
| 7 | same | "For $\gamma$ near one" | Length + Chain ×2: 81 words, 5 sentences covering the $1/(1-\gamma)$ growth, the effective horizon, the guideline, and the cost. "This quantity has a meaning of its own" is filler. Restate: "A longer horizon costs more sweeps" repeats the first sentence. |
| 8 | Q-learning cost | "A Q-learning update costs $O(\|\mathcal{A}\|)$" | Chain: "one sample, so Q-learning needs many updates". |
| 8 | same | "__Every pair needs many visits.__" bullet | Chain: "again and again, so the number of updates". |
| 8 | same | "__A reward travels back one step per update.__" bullet | Chain: "the next state, so a reward reaches". |
| 8 | same | "__Samples have a price.__" bullet | Length: 4 sentences when the bold label counts as one. |
| 9 | same | "Neither method is always cheaper." | Length: 66 words. Multi: sentence 2 joins "faster and more accurate" and "tells us when it has converged". |
| 10 | Limitations | "__Delayed rewards:__" bullet | Chain: "one update at a time, so the agent needs many episodes". |
| 11 | Limitations | "__Overestimation:__" bullet | Length: 114 words. The Double Q-learning sentence alone is about 45 words with four actions. Split into the bias, the example, and the remedy. |
| 11 | Limitations | "The usual answer to the size of the table" | Length: 91 words in 2 sentences. Chain: "so that what the agent learns". Sentence 2 defines a neural network and names Atari in one breath. |
| 13 | Summary | KT 3 "__The table limits tabular Q-learning:__" | Multi: table growth and rounding share one sentence. |
| 13 | Summary | "When we have a model of a small world" | Chain: semicolon, the same shape as the L12a example closer. "surer" is vague. |

## L12d lab (`CHEME-5800-L12d-Lab-ExplorationAndReproducibility-Fall-2026.ipynb`)

| Cell | Section | Starts with | Problem |
|---|---|---|---|
| 0 | title | "In this lab, we use Q-learning to learn how to feed" | Multi: one 45-word sentence holds the task and both failure modes. |
| 0 | title | "__Background:__ A __bioreactor__ is a tank" | Length: 104 words, 5 sentences. Keep the glosses and split at bioreactor and feed, fed-batch and harvest, and lactate and crash. |
| 0 | objectives | LO 2 "__Make a Q-learning result reproducible:__" | Chain: "random choices, so two training runs". |
| 3 | Setup | "The bioreactor model, value iteration, Q-learning" | Chain + Restate: "This code is complete; there is nothing to edit" says one thing twice. |
| 4 | Task 1 | "We describe the culture with three variables" | Chain + Multi: one 50-word sentence with three definitions split by semicolons. These fit as bullets. |
| 4 | Task 1 | "Each cycle $t$, we choose a feed rate" | Chain + Multi: sentence 2 has "which dilutes", a colon, and ", so each concentration falls". |
| 5 | Task 1 | "where $\mu_{\max}$ is the largest growth rate" | Length: 86 words in 2 sentences, both lists of definitions. One bullet per constant. |
| 6 | Task 1 | "We round each new value to the nearest of 21 levels" | Length + Chain: 71 words, 4 sentences, ", so there are $21^{3}$ states". The last sentence has two "which" clauses. The three feeds fit as bullets. |
| 6 | Task 1 | "Every other cycle earns nothing" | Restate: "earns nothing" and "we are paid only at the end" are the same point. |
| 10 | Fixed feed rates | "__What do we see?__ No fixed feed rate" | Length: 4 sentences. The three feed cases fit as bullets. |
| 10 | The optimal policy | "We know the dynamics, so value iteration" | Chain: ", so value iteration gives". |
| 12 | The optimal policy | "__What do we see?__ The optimal policy feeds" | Length: 64 words. Multi: both of the first two sentences carry a ", which" second idea. |
| 13 | Task 2 | "Q-learning makes random choices" | Chain: "and so the same training run". |
| 13 | Task 2 | "> __Training:__ The learning rate" | Length: 69 words, 4 sentences. These fit as bullets. |
| 19 | Task 2 | "__What do we see?__ A different seed" | Length: 58 words, 4 sentences when the "What do we see?" label counts as one. Chain: "not at all, so which policy it learns". "the luck of the draws" is an idiom. |
| 19 | Things to think about | "__Question:__ Set `episodes_new = 200_000`" | Length: 5 sentences. These fit as numbered sub-questions. |
| 22 | Task 3 | "__What do we see?__ The greedy agent never harvests." | Length + Chain: 4 sentences, "without an error, so nothing told us". The last sentence is a lead-in to the code. Split the finding from the lead-in. |
| 24 | Task 3 | "__What do we see?__ The greedy agent only ever chose" | Length + Chain ×3: 65 words, 4 sentences, three ", so" clauses, the densest chain in the week. This would read better as a short numbered cause-and-effect list. Qualifier: "only ever". |
| 28 | Task 3 | "__What do we see?__ The exploring agent" | Multi: each of the 2 sentences joins two ideas with ", and". |
| 28 | Things to think about | "__Question:__ Set `episodes_new = 2_000`" | Length: 75 words, 6 sentences, two experiments in one question. Split into two questions. |
| 29 | Summary | KT 1 "__Value iteration gives the benchmark:__" | Multi: sentence 1 adds the fixed-feed comparison with ", where on our grid". |

## README (`weeks/week-12/README.md`)

| Paragraph | Problem |
|---|---|
| 1, "Week 12 learns a policy from experience" | Length + Chain: 132 words, 5 sentences, and a semicolon. Restate: the meeting-by-meeting walk repeats the table below it. |
| 3, "The L12a lecture and its figures are ported" | Multi: sentence 2 lists three sources joined by commas. |

## Source files (outside the rule's scope)

The rule names lecture and example notebooks. These docstrings break the same
limits, in case you want them consistent. `Compute.jl` is the one students edit:

- `L12b/src/Compute.jl`, the `myqlearning` docstring: 100 words in one block.
- `L12b/src/Utility.jl`, the `build_mdp` docstring (70 words) and the `draw_path` docstring (89 words, a semicolon, ", so").
- `L12d/src/Bioreactor.jl`, the struct docstring (96 words) and the Q-learning `solve` docstring (93 words, ", so").
- `L12a/src/Dosing.jl`, the struct docstring (74 words) and the Q-learning `solve` docstring (65 words, ", so").

## Patterns

- **", so" is the most common breach**, at about 45 places across the week. Most become two sentences by deleting ", so" and starting a new sentence.
- **"What do we see?" blocks in the labs** run to 4 sentences or 60 to 83 words. Each holds the finding, then the reason, then a lead-in to the next cell.
- **"where ..." definition sentences after equations** grow into lists (L12d cell 5, L12a lecture cell 3). These fit as one bullet per symbol.
- **The lab questions** pack two experiments, or three questions plus "Briefly explain.", into one paragraph.
- **The objective and takeaway bullets** keep the house two-sentence form. Two of them still run past 60 words (L12a lecture KT 2 and KT 3), and four chain with ", so" or a second clause.

## Codex cross-check

Codex ran its own read-only pass from the same rule, without seeing this list.
It reported 194 findings in 146 paragraphs, against 108 rows here.

- **Agreement:** every paragraph either pass found over the length limit, and
  every semicolon, ", so", and "and with it", is in the tables above.
- **Added from codex:** the qualifiers ("best possible", "at all", "actually",
  "surer", "only ever"), five restatements, the undefined "qualified name", the
  TODO fragments, and two blocks that reach 4 sentences only when the bold
  label counts as a sentence.
- **Left out:**
  - 33 short ", and" pairs, such as "applies this backup ..., and returns the table".
  - 18 two-part prediction questions.
  - Steps inside the pseudocode.
  - The house "We will use the following example" lead-in.
  - The one-sentence lead-in above the L12c comparison table.
  - "scaled so that 1 is the largest it can grow" in L12a example cell 4.
  The rule allows a short lead sentence, and the pseudocode format is fixed.
  Split the ", and" pairs too if you want the strict reading.
