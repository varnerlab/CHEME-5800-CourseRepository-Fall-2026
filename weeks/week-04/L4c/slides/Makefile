TEXFILE := CHEME-5800-L4c-Slides-Fall-2026.tex
PDF := $(TEXFILE:.tex=.pdf)
STEM := $(basename $(TEXFILE))

LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error

STYLES := vnslides.sty vnslides-base.sty vnflow.sty
SEAL := assets/cornell-seal.pdf

.DEFAULT_GOAL := slides

.PHONY: slides clean distclean

slides: $(PDF)

$(PDF): $(TEXFILE) $(STYLES) $(SEAL)
	$(LATEXMK) -xelatex $(LATEX_FLAGS) $(TEXFILE)

clean:
	$(LATEXMK) -c $(TEXFILE)
	$(RM) $(STEM).nav $(STEM).snm $(STEM).vrb

distclean: clean
	$(RM) $(PDF)
