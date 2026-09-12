TEXFILE := CHEME-5800-L4a-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
RSVG_CONVERT ?= rsvg-convert

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf
FIGURE_SVGS := assets/Fig-General-Graph-Schematic.svg
FIGURE_PDFS := $(FIGURE_SVGS:.svg=.pdf)

TIKZ_PDFS := ../figs/Fig-Degree-Undirected/Fig-Degree-Undirected.pdf \
	../figs/Fig-Degree-Directed/Fig-Degree-Directed.pdf \
	../figs/Fig-Path-Graph/Fig-Path-Graph.pdf \
	../figs/Fig-Star-Graph/Fig-Star-Graph.pdf \
	../figs/Fig-Six-Vertex-Directed-Graph/Fig-Six-Vertex-Directed-Graph.pdf \
	../figs/Fig-Complete-Bipartite-Graph/Fig-Complete-Bipartite-Graph.pdf \
	../figs/Fig-Complete-Graph-Schematic/Fig-Complete-Graph-Schematic-panel.pdf \
	../figs/Fig-Bipartite-Graph-Schematic/Fig-Bipartite-Graph-Schematic-panel.pdf \
	../figs/Fig-General-Tree-Schematic/Fig-General-Tree-Schematic-panel.pdf

.DEFAULT_GOAL := slides
.PHONY: slides figures notebook-figures clean distclean
slides: $(PDF)
figures: $(FIGURE_PDFS) $(TIKZ_PDFS)
notebook-figures:
	$(MAKE) -C ../figs

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(FIGURE_PDFS) $(TIKZ_PDFS)
	$(LATEXMK) -xelatex $(LATEX_FLAGS) $(TEXFILE)

$(TIKZ_PDFS): %.pdf: %.tex
	$(MAKE) -C $(@D)

../figs/Fig-Complete-Graph-Schematic/Fig-Complete-Graph-Schematic-panel.pdf: ../figs/Fig-Complete-Graph-Schematic/Fig-Complete-Graph-Schematic.tex

../figs/Fig-Bipartite-Graph-Schematic/Fig-Bipartite-Graph-Schematic-panel.pdf: ../figs/Fig-Bipartite-Graph-Schematic/Fig-Bipartite-Graph-Schematic.tex

../figs/Fig-General-Tree-Schematic/Fig-General-Tree-Schematic-panel.pdf: ../figs/Fig-General-Tree-Schematic/Fig-General-Tree-Schematic.tex

assets/%.pdf: assets/%.svg
	$(RSVG_CONVERT) -f pdf -o $@ $<

clean:
	$(LATEXMK) -c $(TEXFILE)
	$(RM) $(STEM).nav $(STEM).snm $(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(FIGURE_PDFS)
