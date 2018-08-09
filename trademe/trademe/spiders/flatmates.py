# -*- coding: utf-8 -*-
import scrapy


class FlatmatesSpider(scrapy.Spider):
    name = 'flatmates'
    allowed_domains = ['trademe.co.nz/flatmates-wanted']
    start_urls = ['https://www.trademe.co.nz/flatmates-wanted/auckland']

    def parse(self, response):
        listing_cards = response.xpath('//li[contains(@class, "listingCard")]').extract()
        for listing_card in listing_cards:
        	pass
