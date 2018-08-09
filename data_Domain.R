library(tidyverse)
library(XML)
library(rvest)
library(stringr)
library(lubridate)
library(googledrive)

#URL inicial a buscar
#url <- "https://www.domain.com.au/rent/?suburb=caulfield-vic-3162,south-yarra-vic-3141,windsor-vic-3181,st-kilda-east-vic-3183,caulfield-north-vic-3161,prahran-vic-3181,prahran-east-vic-3181,toorak-vic-3142,elsternwick-vic-3185,balaclava-vic-3183,armadale-vic-3143,elwood-vic-3184,st-kilda-vic-3182&bedrooms=2&price=0-400&ssubs=1"
url <- "https://www.domain.com.au/rent/?suburb=south-yarra-vic-3141,caulfield-north-vic-3161,armadale-vic-3143&bedrooms=2&price=0-400&ssubs=1"

#Lectura de documento
doc <- read_html(url)
doc_parsed <- htmlParse(doc)

#Obtención total de resultados arrojados
results <- xpathSApply(doc_parsed, "//div/h1[@class='search-results__summary']/strong", xmlValue) %>% 
  substr(., start = 1, stop = str_locate(., ",")-1) %>% 
  as.integer()

#Obtención número total de páginas de resultados
pages <- floor(results/20)+1
num_pages <- seq(1, pages, 1)

#Actualización de URL para iteración y extracción
url <- paste0(url, "&page=", num_pages)

#Limpieza
rm(doc, doc_parsed, num_pages, pages, results)

#Extracción de datos
dataset <- map(url, function(url){
  #Leer documento html
  doc <- read_html(url)
  doc_parsed <- htmlParse(doc)
  
  #Obtener y post procesar datos de interés
  price <- xpathSApply(doc_parsed, "//div/p[@class = 'listing-result__price']", xmlValue) %>% 
    str_replace_all(., "[aA-zA]", "") %>% 
    str_trim() %>% 
    str_replace_all(., "\\$", "")
  link <- xpathSApply(doc_parsed, "//div/link[@itemprop='url']", xmlGetAttr, "href")
  address <- xpathSApply(doc_parsed, "//div/a/h2/span[@class = 'address-line1']", xmlValue)
  suburb <- xpathSApply(doc_parsed, "//div/a/h2/span/span[@itemprop='addressLocality']", xmlValue)
  beds <- xpathSApply(doc_parsed, "//div/span[@class='property-feature__feature'][1]", xmlValue)
  baths <- xpathSApply(doc_parsed, "//div/span[@class='property-feature__feature'][2]", xmlValue)
  parking <- xpathSApply(doc_parsed, "//div/span[@class='property-feature__feature'][3]", xmlValue) %>%
    substr(., start = str_locate(., "\\d"), stop = 12)
  
  data <- tibble(Suburb = suburb,
                 Address = address,
                 Bedroom = beds,
                 Bath = baths,
                 Parking = parking,
                 Price = price,
                 Link = link)
})

#Generación de data frame
dataset <- bind_rows(dataset) %>% mutate(DateGathered = today(), Status = "Valid")

#Subir dataset creado a google drive
tmp <- tempfile(fileext = ".csv")
write_csv(dataset, path = tmp)
drive_upload(tmp, path = as_id("1baCzvRlccVIjazbLLl8HF5i4T7lOZuEN?ogsrc=32"), type = "spreadsheet", name = "DomainHousing")

