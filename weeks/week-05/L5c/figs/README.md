# L5c figure provenance

`Fig-ThreeCases-LP-Schematic.svg` is the apples-versus-oranges feasible-region
schematic retained from the CHEME 5800 Fall 2025 lecture repository. It contrasts
the two corner solutions and the equal-slope alternate-optimum case.

On September 16, 2026, the SVG viewport was shortened to remove empty space above
and below the panels. All drawing elements and labels are unchanged.

Original SVG SHA-256: `99e55d7120ed0ca5ce62d0937b337c38253f8b9b257a10031a2b2e031c32db82`

September 16 SVG SHA-256: `bcff2d81c91c297060b996b4a3066261d02070e79464fd50dbea5184a133508f`

On September 22, 2026, the SVG was given the course dark palette used by the L5a
and L5b diagrams. Inkscape's inline `style="fill:...;stroke:..."` colors were
moved to plain `fill` and `stroke` attributes (the drawing is unchanged), the
full-canvas white background path was given `class="canvas"`, and a
`<style id="course-theme">` block was added after the opening tag. The block
makes the canvas transparent on screen, maps each light color to a dark screen
color under `prefers-color-scheme: dark`, and restores the white canvas for
print. The fruit example's image block passes VS Code's selected theme to the
SVG in the same way as the L5a lecture.

Current SVG SHA-256: `e70a5eb9e869dc9fcce7d1543df5cb0304de9e679abb9b2023c4411a59b34cfa`

## Three-vertex minimum-cost-flow example

`Fig-MinCostFlow-ThreeNode.svg` is an original SVG schematic added on September 17,
2026 for the lecture's worked comparison of two source-to-sink routes. Edges 1 and
2 have capacity 2 and cost 1 per unit; direct edge 3 has capacity 3 and cost 5 per
unit. The edge ordering agrees with the incidence matrix in the lecture.

September 17 SHA-256: `b772806c39a108e112d1eca2d5489267b4903b81dc1c59dea5c6b65614cc03c4`

On September 22, 2026, the same `course-theme` style block was added: the white
background rectangle carries `class="canvas"`, and the gray strokes, text, and
node interiors switch to the dark palette under `prefers-color-scheme: dark`.

Current SHA-256: `394baaa6de1e607e6a09ded67aabebfa1251ce3a95753daae0d7cdf8cb046eb6`
