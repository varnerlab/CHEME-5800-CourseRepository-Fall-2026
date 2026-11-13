TEXFILE := CHEME-5800-L13a-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
BUILD_DIR ?= ../../../../build/slides/L13a

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf
FIGURE_STEMS := Fig-HTTP-Messages Fig-URL-Anatomy Fig-JSON-Tree Fig-REST-Cycle Fig-CRUD-Methods
FIGURES := $(foreach stem,$(FIGURE_STEMS),assets/$(stem).pdf)

.DEFAULT_GOAL := slides
.PHONY: slides figures clean distclean
slides: $(PDF)
figures: $(FIGURES)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(FIGURES)
	mkdir -p $(BUILD_DIR)
	$(LATEXMK) -xelatex -outdir=$(BUILD_DIR) $(LATEX_FLAGS) $(TEXFILE)
	cp $(BUILD_DIR)/$(PDF) $(PDF)

# The figures are drawn in TikZ; each figure folder builds the light PDF for
# notes and slides, which is copied here unchanged.
define COPY_FIGURE
assets/$(1).pdf: ../figs/$(1)/$(1).pdf
	mkdir -p assets
	cp $$< $$@
endef
$(foreach stem,$(FIGURE_STEMS),$(eval $(call COPY_FIGURE,$(stem))))

clean:
	$(LATEXMK) -outdir=$(BUILD_DIR) -c $(TEXFILE)
	$(RM) $(BUILD_DIR)/$(STEM).nav $(BUILD_DIR)/$(STEM).snm $(BUILD_DIR)/$(STEM).vrb

distclean: clean
	$(RM) $(PDF) $(BUILD_DIR)/$(PDF)
