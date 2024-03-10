SHELL := /bin/bash
CONFIG = config.json
DATACHECK = data/data.complete
PLOTCHECK = plots/plots.complete
LOCALMAKECHECK = data/local.complete
REMOTEMAKECHECK = data/remote.complete
OUTPUTFOLDER = data/RENAMETHEFOLDER

LOCALDATASET = $(LOCALMAKECHECK) \
				data/*makeflowlog

REMOTEDATASET = $(REMOTEMAKECHECK) \
		data/*.sh \
		data/*makeflowlog \
		data/*.condor* \
		wq-factory*

PLOTS = $(PLOTCHECK) \
		plots/*.dat \
		plots/*.pdf \
		plots/*.plg

CLEAN = log.json \
		wq-factory* \
		data/*.json \
		data/*.sh \
		data/*.condor* \
		data/*.failed*

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

$(LOCALMAKECHECK): $(MAKEFLOW)
	cd data && time makeflow $(MAKEFLOW) -j 1
	touch $(LOCALMAKECHECK)
	mkdir $(OUTPUTFOLDER) && mv $(LOCALDATASET) $(OUTPUTFOLDER)

$(REMOTEMAKECHECK): $(MAKEFLOW)
	work_queue_factory -T condor --password=mypwfile -M nessie_c100_2 -w 100 -W 100 --workers-per-cycle 128 --disk=4096 --memory=8192 --cores=1 &
	sleep 5m
	cd data && time makeflow -T wq --password=mypwfile -M nessie_c100_2 -J 100 -L sugarscape.condor.log --cache-mode never $(MAKEFLOW) > 100.txt
	touch $(REMOTEMAKECHECK)
	mkdir $(OUTPUTFOLDER) && mv $(REMOTEDATASET) $(OUTPUTFOLDER)
	# perl cleanup


all: $(DATACHECK) $(PLOTCHECK)

data: $(DATACHECK)

plots: $(PLOTCHECK)

flow: $(MAKEFLOW)

local: $(LOCALMAKECHECK)

remote: $(REMOTEMAKECHECK)




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
