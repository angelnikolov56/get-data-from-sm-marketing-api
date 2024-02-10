library(httr)
library(tidyverse)
library(googlesheets4)
library(jsonlite)

api_version <- "<API_VERSION>"
url_stem <- "https://graph.facebook.com/"
URL <- paste0(url_stem, api_version, "/", "<YOUR_USER_ID>", "/accounts")
access_token <- "<USER_ACCESS_TOKEN>"

#call insights
tokens <- content(GET
                          (URL,
                            query = list(
                              fields = "name, access_token",
                              access_token = access_token),
                            encode = "json",
                            verbose()))

all_tokens <- data.frame(tokens$data %>% reduce(bind_rows))

# Handle pagination
if(exists("next", tokens$paging) == TRUE){
  # Checking from the originally returned list
  tokens <- fromJSON(tokens$paging$`next`)
  all_tokens <- bind_rows(all_tokens, as_tibble(tokens$data))
  
  # Looping through subsequent returned pages
  while(exists("next", tokens$paging) == TRUE){
    tokens <- fromJSON(tokens$paging$`next`)
    all_tokens <- bind_rows(all_tokens, as_tibble(tokens$data))
  }
}
