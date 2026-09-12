STEM := Fig-Example-Graph
BUILD_DIR := ../../../../build/figures/L4b
LATEXMK ?= latexmk
PDF2SVG ?= pdf2svg
PYTHON ?= python3

.DEFAULT_GOAL := all
.PHONY: all
all: $(STEM).pdf $(STEM).svg

$(STEM).pdf: $(STEM).tex
	mkdir -p $(BUILD_DIR)
	$(LATEXMK) -xelatex -interaction=nonstopmode -halt-on-error -outdir=$(BUILD_DIR) $<
	cp $(BUILD_DIR)/$(STEM).pdf $@

$(STEM).svg: $(STEM).pdf svg_metadata.py
	$(PDF2SVG) $< $@
	$(PYTHON) svg_metadata.py $@
