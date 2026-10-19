TEXFILE := CHEME-5800-L9c-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
BUILD_DIR ?= ../../../../build/slides/L9c

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf
LOGISTIC := assets/Fig-Logistic-Function.pdf
LOGISTIC_SOURCE := ../figs/Fig-Logistic-Function/Fig-Logistic-Function.pdf
GD := assets/Fig-GD-Schematic.pdf
GD_SOURCE := ../figs/Fig-GD-Schematic/Fig-GD-Schematic.pdf
SA := assets/Fig-SA-Schematic.pdf
SA_SOURCE := ../figs/Fig-SA-Schematic/Fig-SA-Schematic.pdf

.DEFAULT_GOAL := slides
.PHONY: slides figures clean distclean
slides: $(PDF)
figures: $(LOGISTIC) $(GD) $(SA)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(LOGISTIC) $(GD) $(SA)
	mkdir -p $(BUILD_DIR)
	$(LATEXMK) -xelatex -outdir=$(BUILD_DIR) $(LATEX_FLAGS) $(TEXFILE)
	cp $(BUILD_DIR)/$(PDF) $(PDF)

$(LOGISTIC): $(LOGISTIC_SOURCE)
	mkdir -p assets
	cp $< $@

$(GD): $(GD_SOURCE)
	mkdir -p assets
	cp $< $@

$(SA): $(SA_SOURCE)
	mkdir -p assets
	cp $< $@

clean:
	$(LATEXMK) -outdir=$(BUILD_DIR) -c $(TEXFILE)
	$(RM) $(BUILD_DIR)/$(STEM).nav $(BUILD_DIR)/$(STEM).snm $(BUILD_DIR)/$(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(BUILD_DIR)/$(PDF)
