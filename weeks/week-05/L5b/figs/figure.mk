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

# The lab notebook embeds every SVG here, so each one carries the dark-theme rules.
$(STEM).svg: $(STEM).pdf ../figure.mk ../theme_svg.py
	$(PDF2SVG) $< $@
	$(PYTHON) ../theme_svg.py $@

clean:
	$(LATEXMK) -c $(STEM).tex

distclean: clean
	$(RM) $(STEM).pdf $(STEM).svg
