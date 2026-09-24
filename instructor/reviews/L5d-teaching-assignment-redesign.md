# L5d redesign: faculty teaching assignment as a minimum-cost flow

Approved by Jeff on 2026-09-23 for the Thu. Sep. 24 meeting. This replaces the
three-worker, four-task L5d lab. The model follows the structure of the
[Teaching-Matching-Problem-CBE](https://github.com/varnerlab/Teaching-Matching-Problem-CBE)
repository, reduced to one semester and rebuilt with synthetic data.

## Format

A guided example that the instructor walks through. The code ships complete, as
in the L5b walkthrough; `src/Compute-solution.jl` is the same file without the
student header. Each task ends with a "Things to think about" subsection in the
CHEME 5820 lab style: questions the class discusses, with no answers in the
notebook. The answers the instructor needs are recorded below and are checked
against actual solves.

## Data (synthetic)

The repository holds real colleagues' names and survey responses, so none of it
is copied. The lab uses ten faculty labeled A–J and twelve public CHEME Fall
course codes and titles. The CSV files contain faculty loads, course staffing
bounds, and the survey preference matrix (0–3 or blank).
At Jeff's request during the manual edit pass on September 23, blank scores now
default to 3 and ENGRI 1120 requires one instructor. Unspecified pairings remain
available; the input CSV preserves blanks while the loaded table shows their
default scores. Course bounds 0–1 mean the course is optional, not required.
The same manual pass removed predetermined faculty–course pairings and their
input file, helper, and figure markings. The solver selects every pairing from
the preference costs, teaching loads, and course staffing requirements.

## Model

Source → faculty → course → completion → sink, the same layers as the L5a and
L5b networks (the completion layer was restored at Jeff's request the same day).
The course → completion edge carries the staffing rule; the completion → sink
edge has capacity equal to the maximum staffing.

| Rule | Edge | Lower | Upper | Cost |
|---|---|---|---|---|
| Exact teaching load | source → faculty | load | load | 0 |
| Survey score 0–3 | faculty → course | 0 | 1 | score |
| Blank input score | faculty → course | 0 | 1 | default 3 |
| Course staffing | course → completion | min | max | 0 |
| Course completion | completion → sink | 0 | max | 0 |

The required flow is the sum of the loads. The pre-solve check requires the
sum of minimum staffing to be at most that flow, and the sum of maximum staffing
to be at least it.

## Notebook

Revised the same day, in order: the structure of the repository's
`FacultyMatching-LP-MinCostMaxFlow-Primal-Fall-2026.ipynb`; the L5c notation;
text tables; completion nodes restored; and finally a leaner, live version.
Jeff: "text is way too dense ... I just want to play with the parameters live in
the lab, have the students guess before we do it, and then discuss", with flow
diagrams rather than tables.

1. Task 1, build the network: course and survey tables, rules as bounds and
   costs, the network drawn in gray, and the totals check.
2. Task 2, formulate and solve: the bounds, w, b, and A assembled in cells, the
   solve, the faculty → courses table, checks, and the flow drawn in red.
3. Task 3, change the data and predict the schedule: two live changes, each a
   "Predict:" prompt, a what-if cell, and a flow diagram. The questions give
   more changes to run live.

## Files

- `weeks/week-05/L5d/`: notebook (same filename), `data/` (department tables and
  README), `src/Compute.jl`, `src/Compute-solution.jl`, `src/FlowPlots.jl`
  (rewritten for this network), `docs/`, `Include.jl`.
- `instructor/validation/week-05/runtests.jl`: L5d ships without TODOs; new
  L5d test set.
- `weeks/week-05/README.md`, `weeks/week-05/release.toml`, and two sentences in
  the L5c lecture that still described a worker–task lab.
- Not changed without Jeff's approval: the L5c slides.

## Verification

Use the Week-5 validation suite, notebook execution, light and dark figure
inspection, and notebook JSON and local-link checks. Preserve the instructor's
manual edits. Input-dependent counts, costs, and staffing outcomes belong in
computed outputs rather than hardcoded prose, as requested during the manual pass.

## Discussion guidance (instructor only)

The manual pass changed the preference default and ENGRI 1120 staffing after
the original redesign. The earlier numerical answer sheet is superseded.
Read the current schedule and costs from the executed notebook and use the
checks in `instructor/validation/week-05/runtests.jl` for the supplied fixture.
Several schedules can tie, so compare costs and constraints before interpreting
a change in the selected faculty. Keep the teaching explanation independent of
input-dependent numerical results.

Tied schedules in the two figures students will predict against. Both
alternatives meet every load and staffing rule at the same minimum cost, so a
student who predicts one of them is right; the figure shows the solver's pick.
The suite pins the schedules the figures show, so a solver update that switches
between tied schedules fails the suite rather than changing a figure silently.

- Starting data, cost 4. Shown: H and J join A on the capstone and E teaches
  CHEME-5310. Tied: E joins the capstone and H teaches CHEME-6440 instead, so
  CHEME-5310 does not run and CHEME-6440 does.
- C rates thermodynamics a 3, cost 6. Shown: C joins the capstone and J takes
  CHEME-3130. Tied: C takes CHEME-6110, F takes ENGRD-2190 (leaving CHEME-6110),
  and A takes CHEME-3130 (leaving ENGRD-2190); J stays on the capstone.

### Task 1

- A blank receives the highest survey score. It remains available and may be
  selected; a large cost does not prohibit an assignment. Prohibiting a pairing
  would require an upper bound of zero or removal of its edge.
- A default score is a modeling assumption, not evidence of the instructor's
  preparation. The original CSV distinguishes unspecified entries from responses.
- An optional course has a zero staffing minimum. It does not run if its
  assigned staffing is zero. Compare total load with required staffing to see
  how many assignments remain for optional courses.
- The aggregate staffing check is necessary but not sufficient. Too few faculty
  with positive loads can prevent a required teaching team from forming even
  when the department-wide totals fit.

### Task 2

- The objective sums the costs of the selected assignments. It does not count
  the same assignment again on the load, staffing, or completion edges.
- Load and staffing checks use the solved flows. Integrality, node balances,
  and recomputed objective cost are checked separately.
- A low department-wide total does not establish a fair allocation. Improving
  J's assignments may worsen someone else's; the total-cost objective does not
  explicitly prioritize the newest faculty member.
- J scored CHEME-6110 and CHEME-6800 a 1, and F teaches both. Moving J to
  CHEME-6110 sends F to J's capstone seat at 3, or to CHEME-6440 at 2 with E
  filling the capstone seat at 1 and CHEME-5310 not running. The cheapest
  schedule that takes J off the capstone costs 5, one more than the optimum:
  J gains a point and F loses two.

### Task 3

- Increasing C's thermodynamics score leaves the starting schedule feasible.
  Compare its added cost with the cost of reassignment; tied optima may select
  different faculty while reporting the same minimum cost.
- C's score 1: cost 5, C keeps CHEME-3130. Score 2: cost 6, and the figure
  shows C keeping it, but the best schedule without C on thermodynamics also
  costs 6, so the two tie and the solver's choice is arbitrary. Score 3: cost 6,
  C moves to the capstone and J takes CHEME-3130. The cost rises one point per
  score point while C stays, then stops at 6, the price of moving C.
- B's sabbatical can now be covered through a default-score pairing. Inspect
  the replacement and the optional courses that no longer run. This example
  illustrates the effect of the default assumption rather than infeasibility.
- A bonus remains negotiable: the solver considers its effect on the total
  cost of a complete schedule. The reported objective includes the bonus
  rather than only the survey-score total.
- J's cost of -1 on CHEME-3130: J teaches it (w=-1), C moves to the capstone
  (w=2), total 3. The move drops J's capstone 2 and C's 0 and adds C's
  capstone 2 plus J's new cost, so it pays only when J's cost is below 0.
  A cost of 1 leaves the starting schedule at cost 4. Do not demonstrate a
  cost of exactly 0: it ties, and GLPK returns a different cost-4 schedule
  with J still on the capstone.
- Improving G's CHEME 2880 score need not move G there: the objective also counts
  the cost of replacing G on the course G would leave.
- In the sabbatical schedule (cost 6), F covers CHEME-2880 at 3 and G teaches
  ENGRI-1120 at 0. Moving G to CHEME-2880 with score s gives a best total of
  5 + s. Score 2: G stays, cost 6. Score 1: a tie at 6. Score 0: G moves,
  cost 5. Who then covers ENGRI-1120 is itself a tie: the figure shows J at 2
  (F returns to CHEME-6110), and I at 1 costs the same (J returns to the
  capstone, E to CHEME-5310, and CHEME-6310 does not run).
- Concentrating all teaching loads on too few faculty can make a required
  teaching team impossible, despite sufficient total load.
