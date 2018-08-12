IMAGE ?= trademe
TAG ?= latest
DCMD ?= docker run --rm -it -u $$(id -u):$$(id -g) -e HOME=/work -v $$(pwd):/work -w /work $(IMAGE):$(TAG)
START_URL ?= trademe.co.nz/flatmates-wanted/auckland

.PHONY: scrapy-shell
scrapy-shell:
	(cd trademe && $(DCMD) scrapy shell $(START_URL))

.PHONY: docker
docker: 
	docker build -t $(IMAGE) . 

.PHONY: run-docker
run-docker:
	$(DCMD) bash

.PHONY: run-docker-root
run-docker-root:
	docker run --rm -it -e HOME=/work -v $$(pwd):/work $(IMAGE):$(TAG) bash
