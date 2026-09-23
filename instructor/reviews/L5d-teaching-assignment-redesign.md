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
course codes and titles. The four CSV files are faculty loads, course staffing
bounds, the survey preference matrix (0–3 or blank), and fixed assignments.

## Model

Source → faculty → course → completion → sink, the same layers as the L5a and
L5b networks (the completion layer was restored at Jeff's request the same day).
The course → completion edge carries the staffing rule; the completion → sink
edge has capacity equal to the maximum staffing.

| Rule | Edge | Lower | Upper | Cost |
|---|---|---|---|---|
| Exact teaching load | source → faculty | load | load | 0 |
| Survey score 0–3 | faculty → course | 0 | 1 | score |
| Blank score | no edge | | | |
| Fixed assignment | faculty → course | 1 | 1 | score |
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

- `weeks/week-05/L5d/`: notebook (same filename), `data/` (four CSVs and
  README), `src/Compute.jl`, `src/Compute-solution.jl`, `src/FlowPlots.jl`
  (rewritten for this network), `docs/`, `Include.jl`.
- `instructor/validation/week-05/runtests.jl`: L5d ships without TODOs; new
  L5d test set.
- `weeks/week-05/README.md`, `weeks/week-05/release.toml`, and two sentences in
  the L5c lecture that still described a worker–task lab.
- Not changed without Jeff's approval: the L5c slides.

## Verification

Week-5 suite, notebook execution, light and dark renders of the figure,
`audit.py` and `notebook_style_check.py --strict`, then one codex read-only pass
over the diff before the week-05.3 release.

## Discussion answers (instructor only)

Every number below comes from solving the model with the lab's code
(2026-09-23). Several schedules can tie; the suite pins the ones named here.

### Task 3 live demos

* *C rates thermodynamics a 3* (`with_preference(department, "C", "CHEME-3130", 3)`):
  C and E swap. E takes CHEME 3130 with a 1 and C joins the capstone with a 2;
  total 7. Keeping C on thermodynamics would cost 5 + 3 = 8, so the swap wins.
  The break-even score is 2: at 2 the swap and staying tie (both 7).
* *B on sabbatical* (`with_load(department, "B", 0)`): infeasible. The totals
  still fit (12 in 11–15), but only B scored CHEME 2880, so its staffing edge
  cannot receive flow. The figure draws the network in gray and says so.

### Task 1

1. *Blank versus 3.* Filling blanks with 3 treats "unknown" as "willing at a
   high cost." In the sabbatical scenario the solver would then quietly assign
   J to CHEME 2880 with a 3 (cost 7) and report a feasible schedule, although J
   never said they could teach the course. The infeasibility, which is the
   useful signal, disappears. (With B present, the base cost stays 5.)
2. *One arrow into CHEME 2880.* CHEME 2880 needs one instructor and only B's
   edge enters it, so B teaches CHEME 2880 in every feasible schedule. B's load
   is 1, so the network fixes B's whole schedule, and B is a single point of
   failure: the sabbatical demo in Task 3.
3. *The two extra assignments.* Only the electives have a maximum above their
   minimum (0 to 1); every other course's minimum equals its maximum. So the two
   assignments beyond the 11 required positions must go to electives, and
   exactly two of the four run (CHEME 6310 and CHEME 6800 in the solved
   schedule).

### Task 2

1. *Lower bounds on the load edges.* With F equal to the total load (13),
   setting those lower bounds to zero changes nothing: the source must send 13
   units and each load edge carries at most the load, so every edge is forced to
   its capacity (cost still 5). The lower bounds matter when F is smaller: with
   F = 12, zero lower bounds give a schedule of cost 4 in which someone teaches
   less than their load, while load-equal lower bounds make the model
   infeasible. The lower bound makes a load an obligation rather than a limit.
2. *Unavoidable cost.* The capstone needs three instructors and only A scores 0,
   so the other two contribute at least 1 each. Everyone who listed CHEME 6110
   scored it 1. So every schedule costs at least 3; the optimum is 5.
3. *Fairness to J.* Other schedules tie at 5 (for example, J on the capstone and
   I on ENGRI 1120), but every cost-5 schedule gives J a 2. Blocking all of J's
   score-2 options raises the cost to 6; the solver's schedule then puts F on
   the capstone with a 3, and another cost-6 schedule gives F a 2 on CHEME 6440
   instead. Sparing the newest faculty member moves the burden to someone
   else, and the total-cost objective cannot express that trade-off.

### Task 3

1. *C's score of 1* (`with_preference(department, "C", "CHEME-3130", 1)`):
   nobody moves; the total rises from 5 to 6, one point per point on an edge in
   use. C gives up the course once the score exceeds 2 (at 2, a tie); the
   live demo's 3 is above that.
2. *Mandate versus bonus.* The mandate (`with_fixed(department, "J", "CHEME-3130")`)
   forces J onto thermodynamics at total 7, a price of 2, and moves four people
   (J to thermodynamics, C to the capstone, H to CHEME 6440, and I to
   ENGRI 1120; CHEME 6310 is cancelled).
   The bonus (`with_cost(department, "J", "CHEME-3130", -1.0)`, a bonus of 3 on
   J's score of 2) also puts J on thermodynamics; the objective is 4, which
   includes the bonus, and the schedule's survey cost is 7. The solver takes the
   preference once the bonus exceeds 2, the mandate's price: with a cost of 0
   (a bonus of exactly 2) the choices tie and the solver keeps C. A bound forces
   the assignment at any price; a cost is weighed against everyone else's
   scores. The two solved schedules differ in who leaves the capstone (H for
   CHEME 6440 under the mandate, E for CHEME 5310 under the bonus); these are
   tied alternatives with the same survey cost of 7.
3. *Fixing the sabbatical*
   (`with_preference(with_load(department, "B", 0), "G", "CHEME-2880", 2)`):
   G takes CHEME 2880 (score 2), I moves from CHEME 6310 into ENGRI 1120
   (score 1), and CHEME 6310 is cancelled; total 8. With 12 assignments for 11
   required positions, only one elective can run.

### Extras, if time allows

* *Flexible capstone* (`with_staffing(department, "CHEME-4320", 2, 4)`): the
  totals become 10 ≤ 13 ≤ 16 and the cost drops to 4; the capstone runs with A
  and H, E moves to CHEME 5310, and three electives run.
* *Stronger pre-solve check.* For each course with a positive minimum, count the
  faculty with a positive load and a score for it. That catches the sabbatical,
  but it is still not sufficient: two courses can each have one eligible
  instructor, the same person, with a load of 1. The complete condition concerns
  every group of courses at once, which is what the solver checks.
* *Doubling or squaring the scores.* Doubling changes only the units. Squaring
  (0, 1, 4, 9) penalizes 2s and 3s more; on this data the schedule does not
  change (squared total 7), and the best schedule that spares J costs 8 squared
  points (F takes CHEME 6440 with a 2).
* *Other ways to cover CHEME 2880:* a visiting lecturer (a new row in
  `Faculty.csv` and `Preferences.csv`), or cancelling the course
  (`with_staffing(department, "CHEME-2880", 0, 1)`).
