# Notebook figure themes

Approved September 20, 2026. Use this convention for new or revised CHEME 5800
notebook diagrams and computed figures. L5a is the initial lecture/example pilot;
L5d applies the plotting convention to a lab. Existing material is migrated when
requested, rather than through an automatic rewrite.

## SVG lecture diagrams

Keep one SVG with its original light palette and a `<style>` block containing
`@media screen and (prefers-color-scheme: dark)` overrides. Adjust text, edges,
arrowheads, nodes, label backgrounds, and shaded regions together. Preserve what
the colors mean. Prefer a transparent outer canvas on screen and light colors
on white for print. Do not invert the whole image.

An SVG loaded through `<img>` needs the notebook to pass along VS Code's chosen
color scheme; the operating-system preference alone is insufficient. Copy the
complete image block from the [L5a lecture](../weeks/week-05/L5a/CHEME-5800-L5a-Lecture-MaximumFlowProblems-Fall-2026.ipynb):
its `.course-diagram` rules set `color-scheme` using
`body[data-vscode-theme-kind]`, with `:host-context(...)` selectors for VS Code's
notebook shadow roots and ordinary selectors for Markdown previews. Keep the
style block in each cell containing a figure. Set `color-scheme: only light` for
print. Other viewers use the color scheme they expose to images.

Preserve descriptive alt text, figure dimensions, and relative paths. For
generated SVGs, retain theme rules in the build pipeline; L5a's
[postprocessor](../weeks/week-05/L5a/figs/theme_svg.py) provides the example for
the cut-optimality TikZ figure. Its PDF continues to use the slide palette.

## Computed figures in examples and labs

After loading `Include.jl`, make the choice visible in the setup cell:

```julia
# Choose one theme; after changing it, rerun this cell and the plotting cells -
theme(:default)   # light background
# theme(:dark)   # dark background
```

Plot helpers should inherit the canvas and foreground from the current Plots
theme, and also accept a `theme` keyword: `:auto` (the default) follows the
global setting, while `:light` or `:dark` draws that one figure on the named
background without changing the global theme. The dark canvas reuses the
background and foreground of Plots' own `theme(:dark)`, so both routes look the
same. Explicit annotations must use the resolved foreground color. Where an
edge color conveys meaning, keep that meaning and choose a contrasting shade
for each background. Filled markers may retain white labels when they remain
readable. See the [L5a helper](../weeks/week-05/L5a/src/FlowPlots.jl) and
[L5d helper](../weeks/week-05/L5d/src/FlowPlots.jl).

The Julia setting affects newly generated plots; switching VS Code's theme does
not recolor saved PNG outputs, and the kernel cannot detect the editor theme.
Students either change the selection in setup and rerun the plotting cells, or
pass `theme = :dark` to a single plotting call. Keep light as the initial
setting and use it for print.

## Verification

Inspect diagrams in the VS Code notebook renderer while previewing a light and
a dark theme, then restore the original editor theme. Render computed figures
with both Plots settings. Check text and arrowheads as well as backgrounds, and
confirm that generated SVGs retain their theme styles after a rebuild.
