FIGURE_DIRS := Fig-Degree-Undirected \
	Fig-Degree-Directed \
	Fig-Path-Graph \
	Fig-Star-Graph \
	Fig-Six-Vertex-Directed-Graph \
	Fig-Complete-Bipartite-Graph \
	Fig-Complete-Graph-Schematic \
	Fig-Bipartite-Graph-Schematic \
	Fig-General-Tree-Schematic

.DEFAULT_GOAL := all
.PHONY: all clean $(FIGURE_DIRS)
all: $(FIGURE_DIRS)

$(FIGURE_DIRS):
	$(MAKE) -C $@

clean:
	@for figure_dir in $(FIGURE_DIRS); do $(MAKE) -C $$figure_dir clean || exit $$?; done
