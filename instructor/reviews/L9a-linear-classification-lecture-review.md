# L9a linear classification lecture review — October 9, 2026

**Status:** Reviewed and approved by the instructor on October 9, 2026 ("let's mark
this reviewed"). Approval covers the lecture at SHA-256
`9aea979f91f8c887f30394da5e9fea632a686630642671a8ecd7792ec95072d6` (uncommitted at
approval). The review is closed.

Target: [Linear Classification and Perceptron lecture](../../weeks/week-09/L9a/CHEME-5800-L9a-Lecture-LinearClassificationAndPerceptron-Fall-2026.ipynb).

Companion: [Banknote Perceptron example](../../weeks/week-09/L9a/CHEME-5800-L9a-Example-LinearModels-Classification-Perceptron-Fall-2026.ipynb),
ported the same day. Its Task 1 copies the lecture's pseudocode verbatim at the
instructor's request, so a pseudocode edit here must be repeated there.

## Source and decisions

The instructor called the week-9 scaffold "very poor" and asked for a rebuild that
uses the 2025 material as the base. The lecture was rebuilt from
`CHEME-5800-L9a-Lecture-LinearModels-Classification-Fall-2025.ipynb`. It keeps the
2025 order, pseudocode format, medical examples, and the "Classical"/"Modern" H3s, in
2026 notation (θ, augmented x̂ with the 1 last, p = m + 1). It is all markdown, 7
cells, with the 2025 linearly separable schematic in `figs/` and a dark-theme style
block.

Instructor decisions, October 9:

- **Keep the Novikoff theorem box.** He rejected condensing it to words, even though
  θ⋆, γ, and R are not used again.
- **Banknotes, 2025 as is.** The L9a example is the 2025 banknote Perceptron, L9b is
  the 2025 XOR lab, and L9d is the 2025 banknote logistic lab. The planning
  document's predictive-maintenance swap is off.
- **The confusion-matrix section was "wonky".** It was reorganized; see Changes.
- **Approved all six re-rating follow-ups.** See Changes.

Declined: blank lines around `$$` displays (the released L7c runs prose straight into
the display in all 22 cases), and a note that precision is undefined at 0/0 (the
lecture never quotes that classifier's precision).

## Scores

| Round | Claude | Codex |
|---|---|---|
| First rating (rebuild as drafted) | 7 | 7 |
| After the rating-round edits | — | 8.5 |
| Independent re-rating, after the confusion-matrix rework | 9 | 9.0 |
| After the six approved follow-ups | — | 9.5 |

## Changes

- **Rebuild additions to 2025:**
  - definitions of decision boundary, hyperplane, linearly separable, online, and
    mistake (y x̂ᵀθ ≤ 0, so a point on the boundary counts);
  - the "Why does this update help?" identity;
  - the Novikoff (R/γ)² box, replacing the unjustified "T = 10n to 100n" rule of thumb;
  - the rare-class accuracy note (3% positive, 97% accurate, zero recall);
  - three house-form objectives and takeaways.
- **Rating round:**
  - objective 2 and takeaway 2 say "misclassified or lies on the boundary";
  - takeaway 2 states the zero-mistake threshold;
  - the example text names the banknote case;
  - the logistic function is glossed;
  - θ ∈ ℝ^p;
  - the decision boundary set is named before its sides are described;
  - ‖x̂‖₂² is glossed as the squared length;
  - the paragraph after the theorem box is rewritten;
  - XOR is described as four wedges, matching the lab's rotated labeling.
- **Confusion-matrix section:**
  - the outcome bullets follow the table (TP, FN, FP, TN) and are defined as counts;
  - one sentence names the diagonal and off-diagonal entries;
  - the medical illustrations moved into one paragraph after the box;
  - "Why the Confusion Matrix Matters" became `### Performance Metrics`;
  - the metric bullets read label = formula and ask "what fraction";
  - specificity gained its "High … means" sentence;
  - the Key insight box is unchanged.
- **Six follow-ups:**
  - the Initialize step's undefined bold **w** became (w₁,…,w_m, b), in both notebooks;
  - the second Rosenblatt link and citation were dropped;
  - the text uses "classifier" and "examples" throughout;
  - "the key performance metrics" became "four performance metrics";
  - "However," was dropped;
  - "later in this week" became "later this week".

## Verification

Strict notebook style check: 0 findings. KaTeX: 90/90 expressions. nbformat
validates. The figure follows the light and dark VS Code themes. The example link
resolves. The L9b sentence matches the rebuilt XOR lab (half circle, wedge, and XOR
labelings). The suite's "L9a banknote Perceptron example" testset checks that the
package `learn(...)` matches the lecture's pseudocode bit for bit. Codex, read-only,
confirmed that the theorem box was byte-identical through the rating round and that
the six follow-ups changed nothing else.

## Open

- **A worked update.** After the one figure, the Perceptron is explained only in prose
  and math. A small two-feature trace or a figure of the boundary moving is the
  remaining gap to 10. It would be a new figure and more length, so it was left as
  the instructor's call.
- **Example review.** Closed on October 9; see the
  [example review record](L9a-banknote-perceptron-example-review.md).
- **Stale planning entry.** The week-9 row of
  `instructor/planning/COURSE-BUILD-QUEUE-WEEKS-01-16.md` still describes the
  predictive-maintenance replacement.
