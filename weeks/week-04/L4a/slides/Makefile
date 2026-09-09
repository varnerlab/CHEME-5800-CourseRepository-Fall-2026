TEXFILE := CHEME-5800-L4a-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
RSVG_CONVERT ?= rsvg-convert

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf
FIGURE_SVGS := \
	assets/Fig-General-Graph-Schematic.svg \
	assets/Fig-Complete-Graph-Schematic.svg \
	assets/Fig-Bipartite-Graph-Schematic.svg \
	assets/Fig-General-Tree-Schematic.svg
FIGURE_PDFS := $(FIGURE_SVGS:.svg=.pdf)
TREE_CROP := assets/Fig-General-Tree-Schematic-crop.pdf

.DEFAULT_GOAL := slides

.PHONY: slides figures clean distclean

slides: $(PDF)

figures: $(FIGURE_PDFS) $(TREE_CROP)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(FIGURE_PDFS) $(TREE_CROP)
	$(LATEXMK) -xelatex $(LATEX_FLAGS) $(TEXFILE)

assets/%.pdf: assets/%.svg
	$(RSVG_CONVERT) -f pdf -o $@ $<

$(TREE_CROP): assets/Fig-General-Tree-Schematic.pdf
	pdfcrop $< $@

clean:
	$(LATEXMK) -c $(TEXFILE)
	$(RM) $(STEM).nav $(STEM).snm $(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(FIGURE_PDFS) $(TREE_CROP)
