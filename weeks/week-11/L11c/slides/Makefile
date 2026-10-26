TEXFILE := CHEME-5800-L11c-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
BUILD_DIR ?= ../../../../build/slides/L11c
RSVG ?= rsvg-convert

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf
FIGURES := assets/Fig-GridWorld-Backup.pdf

.DEFAULT_GOAL := slides
.PHONY: slides figures clean distclean
slides: $(PDF)
figures: $(FIGURES)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(FIGURES)
	mkdir -p $(BUILD_DIR)
	$(LATEXMK) -xelatex -outdir=$(BUILD_DIR) $(LATEX_FLAGS) $(TEXFILE)
	cp $(BUILD_DIR)/$(PDF) $(PDF)

# The notebook figure is an SVG with a dark-mode style block; rsvg-convert
# ignores the media query and writes the light colors. As in the L10a deck, the
# copy converted here adds xml:space="preserve" to every <text> element so
# librsvg keeps the spaces inside labels. The notebook SVG is unchanged.
assets/%.pdf: ../figs/%.svg
	mkdir -p assets
	sed 's/<text /<text xml:space="preserve" /' $< | $(RSVG) -f pdf -o $@

clean:
	$(LATEXMK) -outdir=$(BUILD_DIR) -c $(TEXFILE)
	$(RM) $(BUILD_DIR)/$(STEM).nav $(BUILD_DIR)/$(STEM).snm $(BUILD_DIR)/$(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(BUILD_DIR)/$(PDF)
