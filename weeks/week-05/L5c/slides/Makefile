TEXFILE := CHEME-5800-L5c-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
RSVG_CONVERT ?= rsvg-convert
BUILD_DIR ?= ../../../../build/slides/L5c

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf
FIGURE_PDFS := assets/Fig-ThreeCases-LP-Schematic.pdf \
	assets/Fig-MinCostFlow-ThreeNode.pdf

.DEFAULT_GOAL := slides
.PHONY: slides figures clean distclean
slides: $(PDF)
figures: $(FIGURE_PDFS)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(FIGURE_PDFS)
	mkdir -p $(BUILD_DIR)
	$(LATEXMK) -xelatex -outdir=$(BUILD_DIR) $(LATEX_FLAGS) $(TEXFILE)
	cp $(BUILD_DIR)/$(PDF) $(PDF)

assets/%.pdf: ../figs/%.svg
	$(RSVG_CONVERT) -f pdf -o $@ $<

clean:
	$(LATEXMK) -outdir=$(BUILD_DIR) -c $(TEXFILE)
	$(RM) $(BUILD_DIR)/$(STEM).nav $(BUILD_DIR)/$(STEM).snm $(BUILD_DIR)/$(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(BUILD_DIR)/$(PDF) $(FIGURE_PDFS)
