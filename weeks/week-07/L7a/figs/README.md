# L7a figures

`Fig-Covariance-Schematic` is the lecture-notebook covariance schematic: seeded
bivariate normal samples with negative, zero, and positive covariance, their 1σ
and 2σ covariance ellipses, and a second row overlaying a cloud with four times
the covariance.

The figure is built in the CHEME 5660 Fall 2026 repository, in
`lectures/week-5/L5b/figs` (source `Fig-L5b-Covariance-Schematic.tex`, commit
`c4c8710`), and copied here under a course-neutral name. The build depends on
that repository's shared LaTeX templates, so regenerate it there and copy the
SVG and PDF back.

The SVG carries a dark screen palette in a `<style>` block, and the lecture's
image block passes VS Code's selected theme to it, so changing the editor theme
repaints the figure. Print and the PDF use the light palette.
