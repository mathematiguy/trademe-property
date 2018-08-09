IMAGE ?= trademe
TAG ?= latest
DCMD ?= docker run --rm -it -u $$(id -u):$$(id -g) -e HOME=/work -v $$(pwd):/work -w /work $(IMAGE):$(TAG)

docker: 
	docker build -t $(IMAGE) . 

.PHONY: run-docker
run-docker:
	$(DCMD) bash

.PHONY: run-docker-root
run-docker-root:
	docker run --rm -it -e HOME=/work -v $$(pwd):/work $(IMAGE):$(TAG) bash