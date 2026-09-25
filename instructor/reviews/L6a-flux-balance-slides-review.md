# L6a flux balance analysis slide-deck review

**Original approval:** Reviewed and approved by the instructor on September 25, 2026. That approval covers the 21-slide snapshot below, including the single untitled complete pathway figure immediately before “What Is Metabolic Engineering?”, the approved wording changes, and the Summary. The review is closed.

**Deck:** [L6a: Metabolic Engineering and Flux Balance Analysis](../../weeks/week-06/L6a/slides/CHEME-5800-L6a-Slides-Fall-2026.pdf)

**Editable source:** [LaTeX source](../../weeks/week-06/L6a/slides/CHEME-5800-L6a-Slides-Fall-2026.tex)

**Final editorial score:** 9/10. This is an editorial assessment, not a measured learning outcome.

The deck follows the reviewed lecture's progression from reaction networks and stoichiometric matrices to steady-state balances, the linear program, and enzyme-capacity and exchange bounds. It retains the Week 5 typography and layout. The pathway figure provides network context without a separate pathway-biology discussion. Three learning objectives align with three closing takeaways.

Validation completed during creation and final review:

- Built the PDF with XeLaTeX and latexmk. The final build has no overfull boxes or missing glyphs.
- Rendered and inspected all 21 slides, including the complete pathway figure, equations, parameter tables, and Summary.
- Reviewed coefficient signs, flux units, objective direction, and the stated assumptions behind the full and simplified bounds models.
- Confirmed that the local targets of the notebook links exist, including the stoichiometric-matrix example relocated to L7b.
- Preserved the approved source figure and shared Week 5 style files.

No required changes remain from this review. The parameter tables are relatively dense but serve as reference material. Classroom pacing has not been tested. This approval does not change the Week 6 release status.

Reviewed PDF SHA-256: `48991158566f391faa972a9ba3cabb6bce698484384e259dedc0e7e6310ec514`

Reviewed LaTeX source SHA-256: `62c9d33892ffbadb010bb95c30bd7d7dd6c3f020374c25b461fe989f6f75d1a6`

## September 25 prose and lecture-synchronization pass

Completed the instructor's requested pass for unclear references, omitted
subjects, and compressed phrasing. The current deck has **20 slides**.

- Rewrote explanatory fragments as complete sentences in the objectives,
  definitions, resource and parameter tables, examples, and Summary.
- Named the referenced quantities and clarified how the assumptions affect the
  bounds. Example descriptions begin “In this example, we …”.
- Removed the SVD example slide and opening example link, matching its removal
  from the revised L6a lecture and relocation to L7b.
- Aligned the objective and exchange-bound explanations with the lecture and
  urea notebook: positive exchange means uptake; maximizing negative urea
  exchange maximizes export. The objective equation was updated accordingly.
- Added the lecture's direct KEGG map link to the opening resource slide.
- Preserved the single untitled complete pathway figure, shared style files,
  font sizes, colors, and slide dimensions. Shortened the data-resource heading
  and adjusted Summary spacing so complete sentences fit at the original size.

Validation: rebuilt with XeLaTeX/latexmk, rendered and inspected all 20 pages,
and compared the revised layouts with the original deck. No overfull boxes or
missing characters remain. Three objectives and three takeaways are retained.
No new instructor approval or score is claimed for this subsequent revision.

Current PDF SHA-256: `8b1ebeeb4745d5387fbd818d3cc5a18bc104855782907d793af9cc1c02c5850e`

Current LaTeX SHA-256: `dd2622d18d10f4964f9ccb058508538ec86186ee65c4ccdbc58b0a89347101e6`
