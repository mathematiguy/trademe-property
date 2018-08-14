DOCKER_ID_USER := mathematiguy
REGIONS := northland auckland waikato bay-of-plenty gisborne hawke\'s-bay taranaki manawatu-wanganui wellington nelson-tasman marlborough west-coast canterbury otago southland
DEFAULT_REGION ?= auckland
IMAGE ?= $(DOCKER_ID_USER)/trademe:latest
DCMD ?= docker run --rm -u $$(id -u):$$(id -g) -e HOME=/work -v $$(pwd):/work -w /work
CACHE ?= .config .ipynb_checkpoints .cache .ipython .jupyter .local .ipython .npm .bash_history .python_history
PROJECT_ROOT := $(shell git rev-parse --show-toplevel)
START_URL ?= trademe.co.nz/flatmates-wanted/$(DEFAULT_REGION)/
LOG_LEVEL ?= DEBUG

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
	touch crawls/$*-flatmates.done

watch-%:
	watch -n 0.1 'cat trademe/data/$*-flatmates.csv | \
				  wc -l | \
				  xargs echo Rows scraped: ; \
		          cat trademe/logs/$*-flatmates.log | \
		          grep $(LOG_LEVEL) | \
		          tail -n 30;'

watch-logs:
	watch -n 0.1 'tail -n 2 trademe/logs/*-flatmates.log'

.PHONY: jupyter
jupyter:
	$(DCMD) -p 8888:8888 $(IMAGE) jupyter lab

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
	$(DCMD) $(IMAGE) bash

.PHONY: run-docker-root
run-docker-root:
	-docker run --rm -it -e HOME=/work -v $$(pwd):/work -w /work $(IMAGE) bash

clean-%:
	(cd trademe && rm -rf crawls/$*-flatmates.crawl data/$*-flatmates.csv logs/$*-flatmates.csv)

clean_crawls:
	(cd trademe && rm -rf crawls/* logs/* data/*)

.PHONY: clean-cache
clean_cache:
	find . | \
	grep -oE '$(shell echo $(addprefix [A-Za-z0-9_/\\.]+/\\, $(CACHE)) | \
	sed -e 's/ /|/g')' | \
	uniq | \
	xargs rm -rf
