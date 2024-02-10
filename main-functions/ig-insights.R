library(tidyverse)
library(lubridate)
library(googlesheets4)
library(httr)

api_version <- "<API_VESION>"

ig_post_eng <- c("caption,
                  like_count,
                  comments_count")

ig_post_ins <- c("media_product_type,
                  caption,
                  timestamp,
                  thumbnail_url,
                  media_url,
                  permalink,
                  insights.metric(impressions,reach,total_interactions,saved)")
               

igins_city <- function(access_token, page_account){
  # Paste together URL
  api_version <- api_version
  url_stem <- "https://graph.facebook.com/"
  URL <- paste0(url_stem, api_version, "/", page_account, "/insights")
  
  # Call insights
  content_result <- content(GET
                            (URL,
                              query = list(
                                metric = "follower_demographics",
                                metric_type = "total_value",
                                breakdown = "city",
                                period = "lifetime",
                                access_token = access_token),
                              encode = "json",
                              verbose()))
  
  content_result <- as.data.frame((do.call(rbind, content_result$data[[1]]$total_value$breakdowns[[1]]$results))) %>%
    mutate(dimension_values = unlist(dimension_values)) %>% 
    rename(page_likes = value,
           city = dimension_values)
}


igins_age_gender <- function(access_token, page_account){
  # Paste together URL
  api_version <- api_version
  url_stem <- "https://graph.facebook.com/"
  URL <- paste0(url_stem, api_version, "/", page_account, "/insights")
  
  # Call insights
  content_result <- content(GET
                            (URL,
                              query = list(
                                metric = "follower_demographics",
                                metric_type = "total_value",
                                breakdown = "gender,age",
                                period = "lifetime",
                                access_token = access_token),
                              encode = "json",
                              verbose()))
  
  content_result <- as.data.frame((do.call(rbind, content_result$data[[1]]$total_value$breakdowns[[1]]$results))) %>% 
    mutate(gender = map_chr(dimension_values, 1),  
      age = map_chr(dimension_values, 2), .before = value) %>% 
    select(-dimension_values) %>% 
    rename(page_likes = value) %>% 
    mutate(gender = recode(gender, U = 'Unknown', M = 'Male', F =  'Female'))
}


igins_posts <- function(start_date, until_date, access_token, page_account){
  
  # Paste together URL
  api_version <- api_version
  url_stem <- "https://graph.facebook.com/"
  URL <- paste0(url_stem, api_version, "/", page_account, "/media")
  
  # Call insights
  content_eng <- content(GET
                         (URL,
                           query = list(
                             fields = ig_post_eng,
                             access_token = access_token,
                             since = start_date,
                             until = until_date),
                           encode = "json",
                           verbose()))

  
  content_eng <- map_dfr(content_eng$data, data.frame)
  
  content_ins <- content(GET
                         (URL,
                           query = list(
                             fields = ig_post_ins,
                             access_token = access_token,
                             since = start_date,
                             until = until_date),
                           encode = "json",
                           verbose()))
  
  content_ins <- map_dfr(content_ins$data, data.frame) %>% 
    select(-matches("insights.data.id|insights.data.period|insights.data.description|insights.data.title|insights.data.name|insights.paging")) %>%
    rename(impressions = insights.data.value,
           reach = insights.data.value.1,
           saved = insights.data.value.2,
           engagement = insights.data.value.3) %>%
    mutate(timestamp = as.Date(timestamp))
  
  
  content_eng <- merge(content_eng, content_ins, by = "id") %>%
    select(-caption.y) %>% 
    rename(caption = caption.x)
  
  if (!("thumbnail_url" %in% colnames(content_eng))) {
    content_eng <- content_eng %>% mutate(thumbnail_url = NA)
  }
  
  content_eng <- content_eng %>%
    select(id, caption, timestamp, media_url, permalink, thumbnail_url, media_product_type, impressions, reach, engagement, like_count, comments_count, saved) %>%
    mutate(engagement = ifelse(media_product_type == "REELS", reach, engagement)) %>%
    mutate(reach = ifelse(media_product_type == "REELS", impressions, reach)) %>%
    mutate(impressions = ifelse(media_product_type == "REELS", NA, impressions)) %>% 
    mutate(engagement = ifelse(engagement < (like_count + comments_count + saved), (like_count + comments_count + saved), engagement))
    
}  


igins_page_daily <- function(since_date, until_date, access_token, page_account){
  # Paste together URL
  api_version <- api_version
  url_stem <- "https://graph.facebook.com/"
  URL <- paste0(url_stem, api_version, "/", page_account, "/insights")
  
  # Call insights
  content_result <- content(GET
                            (URL,
                              query = list(
                                metric = "impressions,profile_views,website_clicks",
                                period = "day",
                                access_token = access_token,
                                since = since_date,
                                until = until_date),
                              encode = "json",
                              verbose()))
  
  # Create df with extracted date range
  result_df <- data.frame(content_result$data[[1]][["values"]] %>%
                            reduce(bind_rows)) %>%
    select("end_time")
  
  # Loop through, extract and bind to date only frame
  for(i in seq_along(content_result$data)){
    result_temp <- data.frame()
    if (is.list(content_result$data[[i]]$values[[1]]$value)) {
      result_temp <- as.data.frame(do.call(rbind, content_result$data[[i]]$values)) %>%
        unnest_wider(value)
    } else {
      result_temp <- data.frame(content_result$data[[i]][["values"]] %>%
                                  reduce(bind_rows)) %>%
        rename(!!content_result[["data"]][[i]][["name"]] := value)
    }
    result_df <- merge(result_df, result_temp,  by = "end_time")
  }
  rm(result_temp)
  
  # Trim date character, new column in date class, delete old col and reorder
  result_df <- result_df %>%
    mutate(date=ymd(substr(end_time, start = 1, stop = 10))) %>%
    select(-end_time) %>%
    select(ncol(result_df), 1:ncol(result_df)) 

  result_df <- result_df 
}


igins_followers <- function(access_token, page_account) {
  
  # Paste together URL
  api_version <- api_version
  url_stem <- "https://graph.facebook.com/"
  URL <- paste0(url_stem, api_version, "/", page_account, "?fields=followers_count")
  
  # Call insights
  content_result <- content(GET
                            (URL,
                              query = list(access_token = access_token),
                              encode = "json",
                              verbose()))
  
  content_result <- content_result %>% 
    as_tibble() %>%
    mutate(date = ceiling_date(Sys.Date() %m-% months(1), 'month') %m-% days(1))
  
}


igins_reach <- function(until_date, access_token, page_account) {
  
  # Paste together URL
  api_version <- api_version
  url_stem <- "https://graph.facebook.com/"
  URL <- paste0(url_stem, api_version, "/", page_account, "/insights")
  
  # Call insights
  content_result <- content(GET
                            (URL,
                              query = list(
                                metric = "reach",
                                period = "days_28",
                                access_token = access_token,
                                until = until_date),
                              encode = "json",
                              verbose()))
  
  content_result <- as_tibble(content_result$data[[1]]$values[[2]]) %>%
    mutate(end_time = ymd(substr(end_time, start = 1, stop = 10))) %>%
     rename(reach = value)
  
}
