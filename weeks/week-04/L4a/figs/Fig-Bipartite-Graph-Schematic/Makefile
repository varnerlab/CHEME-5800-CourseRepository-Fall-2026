STEM := Fig-Bipartite-Graph-Schematic
LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
PDF2SVG ?= pdf2svg

.DEFAULT_GOAL := all
.PHONY: all clean
all: $(STEM).pdf $(STEM).svg $(STEM)-panel.pdf $(STEM)-panel.svg ../$(STEM).svg

$(STEM).pdf: $(STEM).tex
	$(LATEXMK) -xelatex $(LATEX_FLAGS) $<

%.svg: %.pdf
	$(PDF2SVG) $< $@
# Keep the original flat SVG path as a generated compatibility export.
../$(STEM).svg: $(STEM).svg
	cp $< $@

$(STEM)-panel.pdf: $(STEM)-panel.tex $(STEM).tex
	$(LATEXMK) -xelatex $(LATEX_FLAGS) $<

clean:
	$(LATEXMK) -c $(STEM).tex
	$(LATEXMK) -c $(STEM)-panel.tex
