DOCKER_ID_USER := mathematiguy
REGIONS := northland auckland waikato bay-of-plenty gisborne hawke\'s-bay taranaki manawatu-wanganui wellington nelson-tasman marlborough west-coast canterbury otago southland
DEFAULT_REGION ?= auckland
IMAGE ?= $(DOCKER_ID_USER)/trademe:latest
DCMD ?= docker run --rm -u $$(id -u):$$(id -g) -e HOME=/work -v $$(pwd):/work -w /work
CACHE_FOLDERS ?= .config .ipynb_checkpoints .cache .ipython .jupyter .local .ipython .npm .bash_history .python_history
START_URL ?= trademe.co.nz/flatmates-wanted/auckland/
LOG_LEVEL ?= DEBUG

.PHONY: crawl
crawl: crawl-$(DEFAULT_REGION)

crawl-all: $(addprefix crawl-, $(REGIONS))

crawl-%:
	(cd trademe && \
	$(DCMD) $(IMAGE) scrapy crawl flatmates \
		-o data/$*-flatmates.csv \
		-s JOBDIR=crawls/$*-flatmates.crawl \
		--loglevel $(LOG_LEVEL) \
		--logfile logs/$*-flatmates.log \
		-a region=$*)

watch-%:
	watch 'cat trademe/logs/$*-flatmates.log | grep $(LOG_LEVEL)'

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

.PHONY: run-docker
run-docker:
	$(DCMD) $(IMAGE) bash

.PHONY: run-docker-root
run-docker-root:
	# Start docker interactive as root
	-docker run --rm -it -e HOME=/work -v $$(pwd):/work -w /work $(IMAGE) bash

clean-crawls:
	(cd trademe && rm -rf crawls/* logs/* data/*)

.PHONY: clean-cache
clean-cache:
	find . -type d | \
	grep -oE $(shell echo $(addprefix [A-Za-z_/\.]+/, $(CACHE_FOLDERS)) | sed -e 's/ /|/g') | \
	uniq | \
	xargs rm -rf