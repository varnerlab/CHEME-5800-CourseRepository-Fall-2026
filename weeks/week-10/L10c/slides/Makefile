TEXFILE := CHEME-5800-L10c-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
BUILD_DIR ?= ../../../../build/slides/L10c

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf
ARMS := assets/Fig-Bandit-Arms.pdf
ARMS_SOURCE := ../figs/Fig-Bandit-Arms/Fig-Bandit-Arms.pdf
UCB := assets/Fig-UCB-Example.pdf
UCB_SOURCE := ../figs/Fig-UCB-Example/Fig-UCB-Example.pdf
THOMPSON := assets/Fig-Thompson-Example.pdf
THOMPSON_SOURCE := ../figs/Fig-Thompson-Example/Fig-Thompson-Example.pdf

.DEFAULT_GOAL := slides
.PHONY: slides figures clean distclean
slides: $(PDF)
figures: $(ARMS) $(UCB) $(THOMPSON)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(ARMS) $(UCB) $(THOMPSON)
	mkdir -p $(BUILD_DIR)
	$(LATEXMK) -xelatex -outdir=$(BUILD_DIR) $(LATEX_FLAGS) $(TEXFILE)
	cp $(BUILD_DIR)/$(PDF) $(PDF)

$(ARMS): $(ARMS_SOURCE)
	mkdir -p assets
	cp $< $@

$(UCB): $(UCB_SOURCE)
	mkdir -p assets
	cp $< $@

$(THOMPSON): $(THOMPSON_SOURCE)
	mkdir -p assets
	cp $< $@

clean:
	$(LATEXMK) -outdir=$(BUILD_DIR) -c $(TEXFILE)
	$(RM) $(BUILD_DIR)/$(STEM).nav $(BUILD_DIR)/$(STEM).snm $(BUILD_DIR)/$(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(BUILD_DIR)/$(PDF)
