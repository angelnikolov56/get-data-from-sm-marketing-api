library(tidyverse)
library(httr)

refresh_token <- "<REFRESH_TOKEN>"
client_id <- "<CLIENT_ID>"
client_secret <- "<CLIENT_SECRET>"


get_linkedin_token <- function() {
  
  URL <- "https://www.linkedin.com/oauth/v2/accessToken"
  header <- "Content-Type: application/x-www-form-urlencoded"

  content_result <- content(POST
                          (URL,
                            query = list(
                              grant_type ="refresh_token",
                              refresh_token = refresh_token,
                              client_id = client_id,
                              client_secret = client_secret),
                            encode = "json",
                            add_headers(header),
                            verbose()))
  
  content_result <- content_result$access_token
  print(content_result)
}
