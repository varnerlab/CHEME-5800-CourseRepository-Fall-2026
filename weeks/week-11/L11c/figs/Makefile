FIGURE_DIRS := Fig-GridWorld Fig-GridWorld-Backup

.DEFAULT_GOAL := all
.PHONY: all clean $(FIGURE_DIRS)
all: $(FIGURE_DIRS)

$(FIGURE_DIRS):
	$(MAKE) -C $@

clean:
	@for figure_dir in $(FIGURE_DIRS); do $(MAKE) -C $$figure_dir clean || exit $$?; done
