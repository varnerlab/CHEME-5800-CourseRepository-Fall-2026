# Included by each diagram's Makefile; paths are relative to that diagram.
LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
PDF2SVG ?= pdf2svg
PYTHON ?= python3

.DEFAULT_GOAL := all
.PHONY: all clean distclean
all: $(STEM).pdf $(STEM).svg

$(STEM).pdf: $(STEM).tex ../vnflow-figure.tex ../figure.mk Makefile
	$(LATEXMK) -xelatex $(LATEX_FLAGS) $(STEM).tex

$(STEM).svg: $(STEM).pdf ../figure.mk
	$(PDF2SVG) $< $@
# The lecture embeds this SVG; retain its theme rules after a TikZ rebuild.
# Slide PDFs keep the original light palette.
ifeq ($(STEM),Fig-Cut-Optimality)
	$(PYTHON) ../theme_svg.py $@

$(STEM).svg: ../theme_svg.py
endif

clean:
	$(LATEXMK) -c $(STEM).tex

distclean: clean
	$(RM) $(STEM).pdf $(STEM).svg
