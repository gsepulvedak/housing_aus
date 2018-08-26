library(tidyverse)
library(XML)
library(rvest)
library(stringr)
library(lubridate)
library(googledrive)
library(googlesheets)
library(gmailr)

#URL inicial a buscar
#url <- "https://www.domain.com.au/rent/?suburb=caulfield-vic-3162,south-yarra-vic-3141,windsor-vic-3181,st-kilda-east-vic-3183,caulfield-north-vic-3161,prahran-vic-3181,prahran-east-vic-3181,toorak-vic-3142,elsternwick-vic-3185,balaclava-vic-3183,armadale-vic-3143,elwood-vic-3184,st-kilda-vic-3182&bedrooms=2&price=0-400&ssubs=1"
url <- "https://www.domain.com.au/rent/?suburb=caulfield-vic-3162,south-yarra-vic-3141&bedrooms=2&price=0-400&ssubs=1"

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
updated_data <- map(url, function(url){
  #Leer documento html
  doc <- read_html(url)
  doc_parsed <- htmlParse(doc)
  
  #Obtener y post procesar datos de interés
  price <- xpathSApply(doc_parsed, "//div/p[@class = 'listing-result__price']", xmlValue) %>% 
    str_replace_all(., "[aA-zA]", "") %>% 
    str_trim() %>% 
    str_replace_all(., "\\$", "") %>% 
    str_replace_all(., "\\..+", "")
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

#Data frame con data actualizada
updated_data <- bind_rows(updated_data)

#Descarga de data en gogle drive y replicar para comparación
old_data <- gs_title("DomainHousing") %>% gs_read(col_types = "cccccccDc") 

#Identificación de registros no vigentes y actualización
NoValid <- dplyr::setdiff(old_data$Link, updated_data$Link)
old_data <- old_data %>% select(-Status) %>% mutate(Status = ifelse(.$Link %in% NoValid, "Not valid", "Valid"))
rm(NoValid)

#Identificación de registros nuevos y adición en dataset
old_data_tmp <- old_data %>% select(-Date, -Status)
new_rows <- dplyr::setdiff(updated_data, old_data_tmp) %>% mutate(Date = today(), Status = "Valid")
new_data <- bind_rows(old_data, new_rows)

#Limpieza
rm(old_data, old_data_tmp, updated_data)

#Actualización googlesheets de drive
id_old <- drive_find(pattern = "DomainHousing", type = "spreadsheet")[2] %>% as.character()
drive_rm(as_id(id_old))
tmp <- tempfile(fileext = ".csv")
write_csv(new_data, path = tmp)
drive_upload(tmp, path = as_id("1baCzvRlccVIjazbLLl8HF5i4T7lOZuEN"), type = "spreadsheet", name = "DomainHousing")

#Envío de mail con novedades del último proceso
gmail_auth("compose")

msg <- mime() %>% 
  from("Proceso Domain") %>% 
  to(c("gsepulvedak@gmail.com")) %>% 
  subject("Nuevas opciones en Melbourne!") %>% 
#  text_body(paste0("Se ha realizado una nueva actualización en la carpeta opendata de RILES.\nMensaje de la operación:\n\n", drive_msg, "\n\nRevisar en https://drive.google.com/drive/u/1/folders/",RILES_id, "\n\nSaludos.", collapse = "\n\n"))

send_message(msg, user_id = "me")
