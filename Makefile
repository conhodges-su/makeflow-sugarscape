SHELL := /bin/bash
CONFIG = config.json
DATACHECK = data/data.complete
PLOTCHECK = plots/plots.complete
MAKECHECK = data/makeflow.complete

DATASET = $(DATACHECK) \
		data/*[[:digit:]]*.config \
		data/*.json \
		data/*.sh \
		data/*.mf* \
		data/*.complete

PLOTS = $(PLOTCHECK) \
		plots/*.dat \
		plots/*.pdf \
		plots/*.plg

CLEAN = log.json \
		$(DATASET) \
		$(PLOTS)

# Change to python3 (or other alias) if needed
PYTHON = python3
SUGARSCAPE = sugarscape.py
MAKEFLOW = sugarscape.mf

$(DATACHECK):
	cd data && $(PYTHON) run.py --conf ../$(CONFIG)
	touch $(DATACHECK)

$(PLOTCHECK): $(DATACHECK)
	cd plots && $(PYTHON) plot.py --path ../data/ --conf ../$(CONFIG) --outf data.dat
	touch $(PLOTCHECK)

$(MAKEFLOW):
	cd data && $(PYTHON) run_mf.py --conf ../$(CONFIG)

$(MAKECHECK): $(MAKEFLOW)
	cd data && time makeflow $(MAKEFLOW) -j 3
	touch $(MAKECHECK)

all: $(DATACHECK) $(PLOTCHECK)

data: $(DATACHECK)

plots: $(PLOTCHECK)

flow: $(MAKEFLOW)

local: $(MAKECHECK)

setup:
	@echo "Setup only works with a local Python 3 installation."
	@echo "Please change the PYTHON variable to the path of your local Python 3 installation in the Makefile if this step fails."
	$(PYTHON) setup.py && mv setup.json $(CONFIG)

test:
	$(PYTHON) $(SUGARSCAPE) --conf $(CONFIG)

clean:
	cd data && makeflow -c $(MAKEFLOW) || true
	rm -rf $(CLEAN) || true

lean:
	rm -rf $(PLOTS) || true

.PHONY: all clean data lean plots setup

# vim: set noexpandtab tabstop=4:
