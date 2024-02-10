library(httr)
library(tidyverse)
library(googlesheets4)
library(jsonlite)
library(rfacebookstat)

fields <- "body,title,call_to_action_type,url_tags,thumbnail_url,image_url" 
token <- "<ACCESS_TOKEN>"
api_version <- "<API_VERSION>"

fb_get_creatives <- function(account_id) {

url_stem <- "https://graph.facebook.com/"
URL <- paste0(url_stem, api_version, "/", paste0("act_", account_id), "/", "adcreatives")
fields <- "body,title,call_to_action_type,url_tags,thumbnail_url,image_url"              

#call insights
result <- content(GET
                  (URL,
                    query = list(
                      fields = fields,
                      thumbnail_width = 1080,
                      thumbnail_height = 1080,
                      limit = 100,
                      access_token = token),
                    encode = "json",
                    verbose()))

result_creatives <- map_dfr(result$data, as.data.frame)

# Looping through all returned pages
while (!is.null(result[["paging"]][["cursors"]][["after"]])) {
  after <- result[["paging"]][["cursors"]][["after"]]
  
  # Make the API call with the 'after' parameter
  result <- content(GET
                    (URL,
                      query = list(
                        fields = fields,
                        thumbnail_width = 1080,
                        thumbnail_height = 1080,
                        limit = 100,
                        after = after,
                        access_token = token),
                      encode = "json",
                      verbose()))
  
  # Append the data to the existing data list
  next_response_dfr <- map_dfr(result$data, as.data.frame)
  result_creatives <- bind_rows(result_creatives, next_response_dfr)
}


result_ads <- fbGetAds(accounts_id = account_id,
                       access_token = token)

result_ads <- result_ads %>%
  select(id, name, creative_id) %>%
  rename(ad_id = id)

result_creatives <- left_join(result_ads, 
                              result_creatives, 
                              by = c("creative_id" = "id"))

result_creatives <- result_creatives %>% 
  mutate(image_url = if_else(is.na(image_url), thumbnail_url, image_url)) %>% 
  select(-thumbnail_url)
}




