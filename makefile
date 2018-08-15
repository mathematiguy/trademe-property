DOCKER_ID_USER := mathematiguy
REGIONS := northland auckland waikato bay-of-plenty gisborne hawke\'s-bay taranaki manawatu-wanganui wellington nelson-tasman marlborough west-coast canterbury otago southland
DEFAULT_REGION ?= auckland
IMAGE ?= $(DOCKER_ID_USER)/trademe:latest
DCMD ?= docker run --rm -u $$(id -u):$$(id -g) -e HOME=/work -v $$(pwd):/work -w /work
CACHE ?= .bash_history .cache .conda .config .ipynb_checkpoints .ipython .jupyter .local .npm .python_history __pycache__
PROJECT_ROOT := $(shell git rev-parse --show-toplevel)
START_URL ?= trademe.co.nz/flatmates-wanted/$(DEFAULT_REGION)/
LOG_LEVEL ?= INFO

.PHONY: crawl
crawl: crawl-$(DEFAULT_REGION)

crawl_all: $(addprefix crawl-, $(REGIONS))

crawl-%:
	(cd trademe && \
	$(DCMD) $(IMAGE) scrapy crawl flatmates \
		-o data/$*-flatmates.csv \
		-s JOBDIR=crawls/$*-flatmates.crawl \
		--loglevel $(LOG_LEVEL) \
		--logfile logs/$*-flatmates.log \
		-a region=$*)

watch-%:
	watch -n 0.1 'cat trademe/data/$*-flatmates.csv | \
				  wc -l | \
				  xargs echo Rows scraped: ; \
				  cat trademe/logs/$*-flatmates.log | \
				  grep $(LOG_LEVEL) | \
				  tail -n 20;'

watch-logs:
	watch -n 0.1 'tail -n 2 trademe/logs/*-flatmates.log'

.PHONY: jupyter
jupyter:
	$(DCMD) -p 8888:8888 $(IMAGE) start.sh jupyter lab

.PHONY: scrapy-shell
scrapy-shell:
	-(cd trademe && $(DCMD) $(IMAGE) scrapy shell $(START_URL))

.PHONY: trademe-docker
trademe-docker:
	-(cd trademe && $(DCMD) $(IMAGE) bash)

.PHONY: docker
docker: 
	docker build -t $(IMAGE) . && \
	docker push $(IMAGE)

pull-docker:
	docker pull $(IMAGE)

.PHONY: run-docker
run-docker:
	$(DCMD) -it $(IMAGE) bash

.PHONY: run-docker-root
run-docker-root:
	-docker run --rm -it -u root:root -e HOME=/work -v $$(pwd):/work -w /work $(IMAGE) bash

clean-%:
	(cd trademe && rm -rf crawls/$*-flatmates.crawl data/$*-flatmates.csv logs/$*-flatmates.log)

clean_crawls:
	(cd trademe && rm -rf crawls/* logs/* data/*)

.PHONY: clean-cache
clean_cache:
	find . | \
	grep -oE '$(shell echo $(addprefix [A-Za-z0-9_/\\.]+/, $(CACHE)) | \
	sed -e 's/ /|/g')' | \
	uniq | \
	xargs rm -rf
