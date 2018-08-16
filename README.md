# trademe-property

This repo contains code using scrapy to collect flatmates data from trademe.co.nz. 

It is fully containerised using Docker, and a makefile is included to make running crawlers easy.

Once everything is installed - `make crawl_all` starts crawlers which crawl each region in NZ.

`make build-flatmates` combines all of the crawled results into a single csv which you can query.
