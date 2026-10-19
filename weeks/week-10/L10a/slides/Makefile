TEXFILE := CHEME-5800-L10a-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
BUILD_DIR ?= ../../../../build/slides/L10a
RSVG ?= rsvg-convert

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf
RL := assets/Fig-Schematic-RL.pdf
RL_SOURCE := ../figs/Fig-Schematic-RL.svg
WMA := assets/Fig-WMA-Weights.pdf
WMA_SOURCE := ../figs/Fig-WMA-Weights/Fig-WMA-Weights.pdf

.DEFAULT_GOAL := slides
.PHONY: slides figures clean distclean
slides: $(PDF)
figures: $(RL) $(WMA)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(RL) $(WMA)
	mkdir -p $(BUILD_DIR)
	$(LATEXMK) -xelatex -outdir=$(BUILD_DIR) $(LATEX_FLAGS) $(TEXFILE)
	cp $(BUILD_DIR)/$(PDF) $(PDF)

# The notebook figure is an SVG with a dark-mode style block; rsvg-convert
# ignores the media query and writes the light colors. Its "state s to s'"
# label places each tspan at a fixed x, and rsvg-convert drops the leading space
# of " to " unless the text keeps its whitespace, so the copy converted here adds
# xml:space="preserve" to every <text> element. The notebook SVG is unchanged.
$(RL): $(RL_SOURCE)
	mkdir -p assets
	sed 's/<text /<text xml:space="preserve" /' $< | $(RSVG) -f pdf -o $@

$(WMA): $(WMA_SOURCE)
	mkdir -p assets
	cp $< $@

clean:
	$(LATEXMK) -outdir=$(BUILD_DIR) -c $(TEXFILE)
	$(RM) $(BUILD_DIR)/$(STEM).nav $(BUILD_DIR)/$(STEM).snm $(BUILD_DIR)/$(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(BUILD_DIR)/$(PDF)
