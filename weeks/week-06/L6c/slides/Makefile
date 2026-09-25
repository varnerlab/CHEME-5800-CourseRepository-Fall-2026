TEXFILE := CHEME-5800-L6c-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))
LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
BUILD_DIR ?= ../../../../build/slides/L6c
STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf

.DEFAULT_GOAL := slides
.PHONY: slides clean distclean
slides: $(PDF)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL)
	mkdir -p $(BUILD_DIR)
	$(LATEXMK) -xelatex -outdir=$(BUILD_DIR) $(LATEX_FLAGS) $(TEXFILE)
	cp $(BUILD_DIR)/$(PDF) $(PDF)

clean:
	$(LATEXMK) -outdir=$(BUILD_DIR) -c $(TEXFILE)
	$(RM) $(BUILD_DIR)/$(STEM).nav $(BUILD_DIR)/$(STEM).snm $(BUILD_DIR)/$(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(BUILD_DIR)/$(PDF)
