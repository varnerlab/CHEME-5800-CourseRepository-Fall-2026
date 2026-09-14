TEXFILE := CHEME-5800-L5a-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf
FIGURE_DIRS := Fig-Residual-FirstFlow Fig-Residual-Augmentation \
	Fig-Residual-RevisedFlow Fig-Cut-Balance Fig-Cut-Optimality \
	Fig-Worker-SourceCut
FIGURE_PDFS := $(foreach figure,$(FIGURE_DIRS),../figs/$(figure)/$(figure).pdf)

.DEFAULT_GOAL := slides
.PHONY: slides figures clean distclean
slides: $(PDF)
figures:
	$(MAKE) -C ../figs

$(PDF): $(TEXFILE) $(STYLES) $(SEAL) $(FIGURE_PDFS)
	$(LATEXMK) -xelatex $(LATEX_FLAGS) $(TEXFILE)

$(FIGURE_PDFS): %.pdf: %.tex ../figs/vnflow-figure.tex ../figs/figure.mk
	$(MAKE) -C $(@D)

clean:
	$(LATEXMK) -c $(TEXFILE)
	$(RM) $(STEM).nav $(STEM).snm $(STEM).vrb

distclean: clean
	$(RM) $(PDF)
