library(tidyverse)
library(XML)
library(rvest)
library(stringr)
library(lubridate)


#url <- "https://www.domain.com.au/rent/?suburb=caulfield-vic-3162,south-yarra-vic-3141,windsor-vic-3181,st-kilda-east-vic-3183,caulfield-north-vic-3161,prahran-vic-3181,prahran-east-vic-3181,toorak-vic-3142,elsternwick-vic-3185,balaclava-vic-3183,armadale-vic-3143,elwood-vic-3184,st-kilda-vic-3182&bedrooms=2&price=0-400&ssubs=1"
url <- "https://www.domain.com.au/rent/?suburb=caulfield-vic-3162&bedrooms=2&price=0-400&ssubs=1"
doc <- read_html(url)
doc_parsed <- htmlParse(doc)
price <- xpathSApply(doc_parsed, "//div/p", xmlValue)
link <- xpathSApply(doc_parsed, "//div/a[@href]", xmlValue)
