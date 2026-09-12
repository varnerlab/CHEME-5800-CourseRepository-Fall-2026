STEM := Fig-Complete-Bipartite-Graph
LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
PDF2SVG ?= pdf2svg

.DEFAULT_GOAL := all
.PHONY: all clean
all: $(STEM).pdf $(STEM).svg

$(STEM).pdf: $(STEM).tex
	$(LATEXMK) -xelatex $(LATEX_FLAGS) $<

%.svg: %.pdf
	$(PDF2SVG) $< $@

clean:
	$(LATEXMK) -c $(STEM).tex
