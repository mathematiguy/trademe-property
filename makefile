DOCKER_ID_USER := mathematiguy
REGIONS := northland auckland waikato bay-of-plenty gisborne hawke\'s-bay taranaki manawatu-wanganui wellington nelson-tasman marlborough west-coast canterbury otago southland
DEFAULT_REGION ?= auckland
IMAGE ?= $(DOCKER_ID_USER)/trademe:latest
DATA_PATH ?= trademe/data/
USER_GROUP ?= -u $$(id -u):$$(id -g)
DCMD ?= docker run --rm -e HOME=/work -v $$(pwd):/work -w /work
CACHE ?= .bash_history .cache .conda .config .ipynb_checkpoints .ipython .jupyter .local .npm .python_history __pycache__
PROJECT_ROOT := $(shell git rev-parse --show-toplevel)
START_URL ?= trademe.co.nz/flatmates-wanted/$(DEFAULT_REGION)/
LOG_LEVEL ?= INFO

.PHONY: build-flatmates
build-flatmates: data/flatmates.csv

data/flatmates.csv: scripts/build-flatmates.py \
	$(addprefix $(DATA_PATH), $(addsuffix -flatmates.csv, $(REGIONS)))
	$(DCMD) $(USER_GROUP) $(IMAGE) python3 $< \
		--data-path $(DATA_PATH) \
		--log-level $(LOG_LEVEL) \
		--output-path $@

.PHONY: crawl
crawl: crawl-$(DEFAULT_REGION)

crawl_all: $(addprefix crawl-, $(REGIONS))

crawl-%:
	(cd trademe && \
	 mkdir crawls/$*-flatmates.crawl && \
	$(DCMD) $(USER_GROUP) $(IMAGE) scrapy crawl flatmates \
		-o data/$*-flatmates.csv \
		-s JOBDIR=crawls/$*-flatmates.crawl \
		--loglevel $(LOG_LEVEL) \
		--logfile logs/$*-flatmates.log \
		--profile crawls/$*-flatmates.crawl/$*.profile \
		--pidfile crawls/$*-flatmates.crawl/$*.pidfile \
		-a region=$*)

$(DATA_PATH)%-flatmates.csv:
	echo $*

watch-%:
	watch -n 0.1 'cat trademe/data/$*-flatmates.csv | \
				  wc -l | \
				  xargs echo Rows scraped: ; \
				  cat trademe/logs/$*-flatmates.log | \
				  grep $(LOG_LEVEL) | \
				  tail -n 20;'

watch_logs:
	watch -n 0.1 'tail -n 1 trademe/logs/*-flatmates.log'

.PHONY: scrapy-shell
scrapy-shell:
	-(cd trademe && $(DCMD) $(USER_GROUP) -it $(IMAGE) scrapy shell $(START_URL))

.PHONY: trademe-docker
trademe-docker:
	-(cd trademe && $(DCMD) $(USER_GROUP) $(IMAGE) bash)

.PHONY: docker
docker: 
	docker build -t $(IMAGE) . && \
	docker push $(IMAGE)

pull-docker:
	docker pull $(IMAGE)

.PHONY: run-docker
run-docker:
	$(DCMD) -it $(USER_GROUP) $(IMAGE) bash

.PHONY: run-docker-root
run-docker-root:
	-docker run --rm -it -e HOME=/work -v $$(pwd):/work -w /work -u root:root $(IMAGE) bash

JUPYTER_PASSWORD ?= password
.PHONY: jupyter
jupyter:
	$(DCMD) -u root:root \
		--rm -it \
		-p 8888:8888 \
		-e NB_USER=$$USER \
		-e NB_UID=$(shell id -u) \
		-e NB_GID=$(shell id -g) \
		jupyter/scipy-notebook \
		jupyter lab \
		--allow-root \
		--NotebookApp.password=$(shell $(DCMD) jupyter/scipy-notebook \
			python -c \
			"from IPython.lib import passwd; print(passwd('$(JUPYTER_PASSWORD)'))"\
			)

clean-%:
	(cd trademe && rm -rf crawls/$*-flatmates.crawl data/$*-flatmates.csv logs/$*-flatmates.log)

clean_crawls:
	(cd trademe && rm -rf crawls/* logs/* data/*)

.PHONY: clean-cache
clean_cache:
	find . | \
	grep -oE '$(shell echo $(addprefix .+/, $(CACHE)) | \
	sed -e 's/ /|/g')' | \
	uniq | \
	xargs rm -rf

echo-variables:
	@ echo DOCKER_ID_USER:   $(DOCKER_ID_USER)
	@ echo REGIONS:          $(REGIONS)
	@ echo DEFAULT_REGION:   $(DEFAULT_REGION)
	@ echo IMAGE:            $(IMAGE)
	@ echo DATA_PATH:        $(DATA_PATH)
	@ echo USER_GROUP:       $(USER_GROUP)
	@ echo DCMD:             $(DCMD)
	@ echo CACHE:            $(CACHE)
	@ echo PROJECT_ROOT:     $(PROJECT_ROOT)
	@ echo START_URL:        $(START_URL)
	@ echo JUPYTER_PASSWORD: $(JUPYTER_PASSWORD)
	@ echo JUPYTER_PW_HASH:  $(JUPYTER_PW_HASH)
	@ echo LOG_LEVEL:        $(LOG_LEVEL)
