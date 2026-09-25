TEXFILE := CHEME-5800-L6a-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
BUILD_DIR ?= ../../../../build/slides/L6a

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf
MAP := assets/Fig-Central-Metabolism.pdf
MAP_SOURCE := ../figs/Fig-Central-Metabolism/Fig-Central-Metabolism.pdf

.DEFAULT_GOAL := slides
.PHONY: slides figures clean distclean
slides: $(PDF)
figures: $(MAP)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(MAP)
	mkdir -p $(BUILD_DIR)
	$(LATEXMK) -xelatex -outdir=$(BUILD_DIR) $(LATEX_FLAGS) $(TEXFILE)
	cp $(BUILD_DIR)/$(PDF) $(PDF)

$(MAP): $(MAP_SOURCE)
	mkdir -p assets
	cp $< $@

clean:
	$(LATEXMK) -outdir=$(BUILD_DIR) -c $(TEXFILE)
	$(RM) $(BUILD_DIR)/$(STEM).nav $(BUILD_DIR)/$(STEM).snm $(BUILD_DIR)/$(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(BUILD_DIR)/$(PDF)
