library(tidyverse)
library(lubridate)
library(httr)
library(janitor)

fields <- "costInLocalCurrency,
           impressions,
           dateRange,
           pivotValues,
           approximateUniqueImpressions,
           clicks,
           comments,
           follows,
           postClickJobApplications,
           postClickJobApplyClicks,
           likes,
           reactions,
           registrations,
           shares,
           totalEngagements,
           videoCompletions,
           oneClickLeads,
           oneClickLeadFormOpens,
           otherEngagements,
           videoViews"

linkedin_ads_daily <- function(date_start, date_end, account_id, access_token) {
  
  # Set URL and parameters
  endpoint <- "https://api.linkedin.com/rest/adAnalytics"
  q <- "analytics"
  pivot <- "CAMPAIGN"
  timeGranularity <- "DAILY"

  # Fetch data from the API 
  result <- content(GET
                    (endpoint,
                      query = list(
                        q = q,
                        pivot = pivot,
                        dateRange.start.day = day(date_start),
                        dateRange.start.month = month(date_start),
                        dateRange.start.year = year(date_start),
                        dateRange.end.day	= day(date_end),
                        dateRange.end.month	= month(date_end),
                        dateRange.end.year	= year(date_end),
                        timeGranularity = timeGranularity,
                        accounts = paste0("urn:li:sponsoredAccount:", account_id),
                        fields = fields,
                        projection = "(*,elements*(*,pivotValues(*~sponsoredCampaign(name))))"),
                      encode = "json",
                      add_headers("Authorization" = paste0("Bearer ", access_token)),
                      add_headers("LinkedIn-Version" = "202302"),
                      verbose()))
  
  # Combine the date fields into a single value in a yyyy-mm-dd format
  for (i in seq_along(result$elements)) {
    result$elements[[i]]$dateRange <- as.Date(
      paste(
        result$elements[[i]]$dateRange$start$year,
        result$elements[[i]]$dateRange$start$month, 
        result$elements[[i]]$dateRange$start$day, 
        sep = "-"))
  }
  
  # Unnest campaign id
  for (i in seq_along(result$elements)) {
    result$elements[[i]]$pivotValues <- result$elements[[i]]$pivotValues[[1]]
  }
  
  # Convert the list to a data frame
  result <- map_dfr(result$elements, data.frame)
  
  # Rename some columns, convert column names to snake_case, trim the campaign id column, set appropriate data types                    
  result <- result %>%
    clean_names() %>%
    rename(campaign_id = pivot_values,
           campaign_name = name,
           reach = approximate_unique_impressions) %>%
    mutate(campaign_id = str_extract(campaign_id, "\\d.*"),
           cost_in_local_currency = as.double(cost_in_local_currency)) %>%
    mutate_at(vars(-c(campaign_name, campaign_id, date_range, cost_in_local_currency)), as.numeric) %>% 
    arrange(date_range)
}
