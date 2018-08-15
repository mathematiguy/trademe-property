FROM jupyter/scipy-notebook

USER root

# Install prerequisites for scrapy
RUN apt-get update && \
	apt-get install --assume-yes --no-install-recommends \
		gcc \
		libffi-dev \
		libssl-dev \
		libxml2-dev \
		libxslt1-dev \
		python-pip \
		python-dev \
		zlib1g-dev && \
	apt-get clean && \
	rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Pip install requirements.txt
COPY requirements.txt /root/requirements.txt
RUN pip install -r /root/requirements.txt

USER $NB_UID