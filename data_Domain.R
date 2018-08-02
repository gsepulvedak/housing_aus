library(tidyverse)
library(XML)
library(rvest)
library(stringr)
library(lubridate)


#url <- "https://www.domain.com.au/rent/?suburb=caulfield-vic-3162,south-yarra-vic-3141,windsor-vic-3181,st-kilda-east-vic-3183,caulfield-north-vic-3161,prahran-vic-3181,prahran-east-vic-3181,toorak-vic-3142,elsternwick-vic-3185,balaclava-vic-3183,armadale-vic-3143,elwood-vic-3184,st-kilda-vic-3182&bedrooms=2&price=0-400&ssubs=1"
url <- "https://www.domain.com.au/rent/?suburb=caulfield-vic-3162&bedrooms=2&price=0-400&ssubs=1&page=1"
doc <- read_html(url)
doc_parsed <- htmlParse(doc)
price <- xpathSApply(doc_parsed, "//div/p[@class = 'listing-result__price']", xmlValue)
link <- xpathSApply(doc_parsed, "//div/link[@itemprop='url']", xmlGetAttr, "href")
address <- xpathSApply(doc_parsed, "//div/a/h2/span[@class = 'address-line1']", xmlValue)
suburb <- xpathSApply(doc_parsed, "//div/a/h2/span/span[@itemprop='addressLocality']", xmlValue)
beds <- xpathSApply(doc_parsed, "//div/span[@class='property-feature__feature'][1]", xmlValue)
baths <- xpathSApply(doc_parsed, "//div/span[@class='property-feature__feature'][2]", xmlValue)
parking <- str_replace(xpathSApply(doc_parsed, "//div/span[@class='property-feature__feature'][3]", xmlValue),"− ", "")