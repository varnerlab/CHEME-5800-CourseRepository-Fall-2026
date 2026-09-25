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
GEOM := assets/Fig-FBA-FeasibleSpace.pdf
GEOM_SOURCE := ../figs/Fig-FBA-FeasibleSpace/Fig-FBA-FeasibleSpace.pdf
CV := assets/Fig-Stoichiometric-ControlVolume.pdf
CV_SOURCE := ../figs/Fig-Stoichiometric-ControlVolume/Fig-Stoichiometric-ControlVolume.pdf

.DEFAULT_GOAL := slides
.PHONY: slides figures clean distclean
slides: $(PDF)
figures: $(MAP) $(GEOM) $(CV)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(MAP) $(GEOM) $(CV)
	mkdir -p $(BUILD_DIR)
	$(LATEXMK) -xelatex -outdir=$(BUILD_DIR) $(LATEX_FLAGS) $(TEXFILE)
	cp $(BUILD_DIR)/$(PDF) $(PDF)

$(MAP): $(MAP_SOURCE)
	mkdir -p assets
	cp $< $@

$(GEOM): $(GEOM_SOURCE)
	mkdir -p assets
	cp $< $@

$(CV): $(CV_SOURCE)
	mkdir -p assets
	cp $< $@

clean:
	$(LATEXMK) -outdir=$(BUILD_DIR) -c $(TEXFILE)
	$(RM) $(BUILD_DIR)/$(STEM).nav $(BUILD_DIR)/$(STEM).snm $(BUILD_DIR)/$(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(BUILD_DIR)/$(PDF)
