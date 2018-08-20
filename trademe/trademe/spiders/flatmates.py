# -*- coding: utf-8 -*-
import re
import scrapy
import warnings
from datetime import datetime


def get_view_count(flat_response):
    view_digits = flat_response.xpath('//*[@id="DetailsFooter_PageViewsPanel"]/img/@alt').extract()
    view_digits = ''.join(view_digits)
    result = '' if len(view_digits) == 0 else ''.join(view_digits)
    return result


def normalize_variable_name(var_name):
	return var_name.replace(":", "").replace(" ", "_").lower()


def clean_values(text):
    text = text.replace("<br>", "\n")
    text = '\n\n'.join([s.strip() for s in re.findall('<td>([^<]+)</td>', text, flags=re.MULTILINE)])
    text = text.strip()
    return text


class FlatmatesSpider(scrapy.Spider):
    name = 'flatmates'
    allowed_domains = ['trademe.co.nz']
    start_urls = []
    current_time = datetime.now().strftime("%a %d %b %Y")

    def __init__(self, *args, **kwargs):
        region = kwargs.pop('region', []) 
        if region:
            self.start_urls.append('https://www.trademe.co.nz/flatmates-wanted/' + region)
        self.logger.info(self.start_urls)
        super(FlatmatesSpider, self).__init__(*args, **kwargs)

    def parse(self, response):

        flat_hrefs = response.xpath(
            '//div[contains(@class, "flatmates-list-view-card-title")]/a/@href'
            ).extract()
        for href in flat_hrefs:
            href = re.sub("\?.*", "", href)
            flat_href = response.urljoin(href)
            yield scrapy.Request(flat_href, callback = self.parse_flat)

        page_hrefs = response.xpath('//table[@id="PagingFooter"]/tr/td/a/@href').extract()
        for href in page_hrefs:
            page_href = response.urljoin(href)
            yield scrapy.Request(page_href, callback = self.parse)

    def parse_flat(self, response):

        page_title = response.xpath("//title/text()").extract()[0]
        if page_title == "Sorry, this classified has expired - Trade Me":
            warnings.warn("The page has expired")
            yield None

        attribute_names  = [normalize_variable_name(t.strip()) \
        	for t in response.xpath('//table[@id="ListingAttributes"]/tr/th/text()').extract()]

        attribute_values = [clean_values(t.extract()) \
        	for t in response.xpath('//table[@id="ListingAttributes"]/tr/td')]
        assert len(attribute_names) == len(attribute_values), \
            "attribute_names and attribute_values have different lengths"

        results = dict(zip(attribute_names, attribute_values))
        div_pattern = '//div[contains(@class, "{}")]/text()'

        results['url']         = response.url
        results['title']       = response.xpath('//h1/text()').extract_first().strip()
        results['rent']        = response.xpath(div_pattern.format("title-price")).extract_first().strip()
        results['id_number']   = response.xpath(div_pattern.format("property-listing-id")).extract_first().strip()
        results['listed_date'] = response.xpath(div_pattern.format("listing-number-box")).extract_first().strip()
        results['view_count']  = get_view_count(response)
        results['current_time'] = self.current_time

        yield results
