FROM python:3.6

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

COPY requirements.txt /root/requirements.txt
RUN pip3 install -r /root/requirements.txt

CMD ["scrapy", "shell", "--nolog"]