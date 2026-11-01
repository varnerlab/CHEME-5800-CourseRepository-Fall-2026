# Included by each diagram's Makefile; paths are relative to that diagram.
LATEXMK ?= latexmk
LATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error
PDF2SVG ?= pdf2svg
PYTHON ?= python3

.DEFAULT_GOAL := all
.PHONY: all clean distclean
all: $(STEM).pdf $(STEM).svg ../$(STEM).svg

$(STEM).pdf: $(STEM).tex ../mdp-figure.tex ../figure.mk Makefile
	$(LATEXMK) -pdf $(LATEX_FLAGS) $(STEM).tex

# The notebooks embed the SVG; add the dark screen palette after each rebuild.
$(STEM).svg: $(STEM).pdf ../theme_svg.py ../figure.mk
	$(PDF2SVG) $< $@
	$(PYTHON) ../theme_svg.py $@

# The notebooks, slides, and release manifest use the flat path figs/$(STEM).svg.
../$(STEM).svg: $(STEM).svg
	cp $< $@

clean:
	$(LATEXMK) -c $(STEM).tex

distclean: clean
	$(RM) $(STEM).pdf $(STEM).svg
