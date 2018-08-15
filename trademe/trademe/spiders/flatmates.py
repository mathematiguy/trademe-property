# -*- coding: utf-8 -*-
import scrapy
import warnings

def get_page_count(flat_response):
    view_digits = flat_response.xpath('//*[@id="DetailsFooter_PageViewsPanel"]/img/@alt').extract()
    view_digits = ''.join(view_digits)
    if len(view_digits) == 0:
        return 0
    else:
        return int(''.join(view_digits))

def normalize_variable_name(var_name):
	return var_name.replace(":", "").replace(" ", "_").lower()

class FlatmatesSpider(scrapy.Spider):
    name = 'flatmates'
    allowed_domains = ['trademe.co.nz']

    def __init__(self, *args, **kwargs):
        region = kwargs.pop('region', []) 
        if region:
            self.start_urls = ['https://www.trademe.co.nz/flatmates-wanted/' + region]
        self.logger.info(self.start_urls)
        super(FlatmatesSpider, self).__init__(*args, **kwargs)

    def parse(self, response):

        flat_hrefs = response.xpath(
            '//div[contains(@class, "flatmates-list-view-card-title")]/a/@href'
            ).extract()
        for href in flat_hrefs:
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
        attribute_values = [t.strip() \
        	for t in response.xpath('//table[@id="ListingAttributes"]/tr/td/text()').extract()]

        results = dict(zip(attribute_names, attribute_values))
        div_pattern = '//div[contains(@class, "{}")]/text()'

        results['url']        = response.url
        results['title']      = [t.strip() for t in response.xpath('//h1/text()').extract()]
        results['bedrooms']   = [t.strip() for t in response.xpath('//h1/text()').re("[\d\+<>]+ bedrooms?")]
        results['rent']       = [t.strip() for t in response.xpath(div_pattern.format("title-price")).re("\d+")]
        results['id_number']  = [t.strip() for t in response.xpath(div_pattern.format("property-listing-id")).extract()]
        results['date']       = [t.strip() for t in response.xpath(div_pattern.format("listing-number-box")).extract()]
        results['view_count'] = get_page_count(response)

        yield results
