# Included by each diagram's Makefile; paths are relative to that diagram.
LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
PDF2SVG ?= pdf2svg

.DEFAULT_GOAL := all
.PHONY: all clean distclean
all: $(STEM).pdf $(STEM).svg

$(STEM).pdf: $(STEM).tex ../vnflow-figure.tex ../figure.mk Makefile
	$(LATEXMK) -xelatex $(LATEX_FLAGS) $(STEM).tex

$(STEM).svg: $(STEM).pdf
	$(PDF2SVG) $< $@

clean:
	$(LATEXMK) -c $(STEM).tex

distclean: clean
	$(RM) $(STEM).pdf $(STEM).svg
