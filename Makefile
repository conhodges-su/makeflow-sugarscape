SHELL := /bin/bash
CONFIG = config.json
DATACHECK = data/data.complete
PLOTCHECK = plots/plots.complete
LOCALMAKECHECK = data/local.complete
REMOTEMAKECHECK = data/remote.complete
OUTPUTFOLDER = data/RENAMETHEFOLDER
HOST = ap21.uc.osg-htc.org
PORT = 1024

LOCALDATASET = $(LOCALMAKECHECK) \
				data/*.config \
				data/*.json \
				data/*makeflowlog \
				data/*.mf*

REMOTEDATASET = $(REMOTEMAKECHECK) \
		data/*[[:digit:]]*.config \
		data/*.json \
		data/*.sh \
		data/*.mf* \
		data/*.condor* \
		wq-factory*

PLOTS = $(PLOTCHECK) \
		plots/*.dat \
		plots/*.pdf \
		plots/*.plg

CLEAN = log.json \
		wq-factory* \
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

$(LOCALMAKECHECK): $(MAKEFLOW)
	cd data && time makeflow $(MAKEFLOW) -j 1
	touch $(LOCALMAKECHECK)
	mkdir $(OUTPUTFOLDER) && mv $(LOCALDATASET) $(OUTPUTFOLDER)

$(REMOTEMAKECHECK): $(MAKEFLOW)
	# openssl req -x509 -newkey rsa:4096 -keyout MY_KEY.pem -out MY_CERT.pem -sha256 -days 365 -nodes
	# work_queue_factory -T condor --password=mypwfile -M nessie -w 64 -W 64 --workers-per-cycle 20 --ssl=$(HOST):$(PORT) &
	work_queue_factory -T condor --password=mypwfile -M nessie -w 1 -W 64 --workers-per-cycle 20 --condor-requirements='Memory > 4096' &
	cd data && time makeflow -T wq --password=mypwfile -M nessie -J 64 -L sugarscape.condor.log $(MAKEFLOW)
	touch $(REMOTEMAKECHECK)
	mkdir $(OUTPUTFOLDER) && mv $(REMOTEDATASET) $(OUTPUTFOLDER)
	perl cleanup


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
