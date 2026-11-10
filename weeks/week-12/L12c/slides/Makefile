TEXFILE := CHEME-5800-L12c-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
BUILD_DIR ?= ../../../../build/slides/L12c
RSVG ?= rsvg-convert

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf
QTABLE := assets/Fig-Q-Schematic.pdf
QTABLE_SOURCE := ../../L12a/figs/Fig-Q-Schematic.svg
QNETWORKS := assets/Fig-Q-Networks.pdf
QNETWORKS_SOURCE := ../figs/Fig-Q-Networks/Fig-Q-Networks.pdf
FIGURES := $(QTABLE) $(QNETWORKS)

.DEFAULT_GOAL := slides
.PHONY: slides figures clean distclean
slides: $(PDF)
figures: $(FIGURES)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(FIGURES)
	mkdir -p $(BUILD_DIR)
	$(LATEXMK) -xelatex -outdir=$(BUILD_DIR) $(LATEX_FLAGS) $(TEXFILE)
	cp $(BUILD_DIR)/$(PDF) $(PDF)

# The Q-table figure is the L12a lecture's SVG, which the L12c lecture also
# shows. It carries a dark-mode style block; rsvg-convert ignores the media query
# and writes the light colors. As in the L12a deck, the converted copy adds
# xml:space="preserve" to every <text> element so librsvg keeps the spaces inside
# labels. The SVG itself is unchanged.
$(QTABLE): $(QTABLE_SOURCE)
	mkdir -p assets
	sed 's/<text /<text xml:space="preserve" /' $< | $(RSVG) -f pdf -o $@

# The Q-networks figure is drawn in TikZ; its folder builds the light PDF for
# notes and slides, which is copied here unchanged.
$(QNETWORKS): $(QNETWORKS_SOURCE)
	mkdir -p assets
	cp $< $@

clean:
	$(LATEXMK) -outdir=$(BUILD_DIR) -c $(TEXFILE)
	$(RM) $(BUILD_DIR)/$(STEM).nav $(BUILD_DIR)/$(STEM).snm $(BUILD_DIR)/$(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(BUILD_DIR)/$(PDF)
