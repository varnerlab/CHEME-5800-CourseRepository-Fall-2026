# Build the L7c regression schematic: a PDF from the TikZ source, then the
# notebook SVG. Requires XeLaTeX, pdf2svg, and Python 3 (standard library).

STEM := Fig-LinearRegressionModel-Schematic

XELATEX ?= xelatex
PDF2SVG ?= pdf2svg
PYTHON ?= python3
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error

.PHONY: all clean distclean
.DEFAULT_GOAL := all

all: $(STEM).pdf $(STEM).svg

$(STEM).pdf: $(STEM).tex Makefile
	$(XELATEX) $(LATEX_FLAGS) $<

# PDF conversion traces glyphs to paths, so the notebook SVG needs no fonts.
# theme_svg.py then adds the dark screen palette the lecture notebook relies on;
# the PDF keeps the light palette for notes and slides.
$(STEM).svg: $(STEM).pdf theme_svg.py
	$(PDF2SVG) $< $@
	$(PYTHON) theme_svg.py $@

clean:
	$(RM) *.aux *.log *.xdv *.fls *.fdb_latexmk *.out

distclean: clean
	$(RM) $(STEM).pdf $(STEM).svg

# A failed theme step must not leave an unthemed SVG that later looks current.
.DELETE_ON_ERROR:
