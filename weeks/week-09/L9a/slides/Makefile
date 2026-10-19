TEXFILE := CHEME-5800-L9a-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
BUILD_DIR ?= ../../../../build/slides/L9a
RSVG ?= rsvg-convert

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf
SEP := assets/Fig-LinearlySeparable-Schematic.pdf
SEP_SOURCE := ../figs/Fig-LinearlySeparable-Schematic.svg

.DEFAULT_GOAL := slides
.PHONY: slides figures clean distclean
slides: $(PDF)
figures: $(SEP)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(SEP)
	mkdir -p $(BUILD_DIR)
	$(LATEXMK) -xelatex -outdir=$(BUILD_DIR) $(LATEX_FLAGS) $(TEXFILE)
	cp $(BUILD_DIR)/$(PDF) $(PDF)

# The notebook figure is an SVG with a dark-mode style block; rsvg-convert
# ignores the media query and writes the light colors.
$(SEP): $(SEP_SOURCE)
	mkdir -p assets
	$(RSVG) -f pdf -o $@ $<

clean:
	$(LATEXMK) -outdir=$(BUILD_DIR) -c $(TEXFILE)
	$(RM) $(BUILD_DIR)/$(STEM).nav $(BUILD_DIR)/$(STEM).snm $(BUILD_DIR)/$(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(BUILD_DIR)/$(PDF)
