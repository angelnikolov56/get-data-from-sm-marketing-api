library(tidyverse)
library(lubridate)
library(googlesheets4)
library(httr)

api_version <- "<API_VERSION>"

fields_post_eng <- c("message,
                     reactions.summary(true),
                     comments.summary(true),
                     shares.summary(true)") 

fields_post_ins <- c("message,
                      created_time,
                      full_picture,
                      permalink_url,
                      insights.metric(post_impressions,
                      post_impressions_organic,
                      post_impressions_paid,
                      post_impressions_viral,
                      post_impressions_unique,
                      post_impressions_organic_unique,
                      post_impressions_paid_unique,
                      post_impressions_viral_unique,
                      post_engaged_users,
                      post_clicks_by_type)")

n_metrics <- seq(1:8)                      

metrics_page <- c("page_engaged_users, 
                   page_post_engagements, 
                   page_impressions, 
                   page_impressions_unique, 
                   page_impressions_paid, 
                   page_impressions_paid_unique, 
                   page_impressions_organic_v2, 
                   page_impressions_organic_unique_v2, 
                   page_impressions_viral, 
                   page_impressions_viral_unique, 
                   page_fan_adds,
                   page_fan_removes,	
                   page_actions_post_reactions_like_total,
                   page_actions_post_reactions_love_total,
                   page_actions_post_reactions_wow_total,
                   page_actions_post_reactions_haha_total,
                   page_actions_post_reactions_sorry_total,
                   page_actions_post_reactions_anger_total,
                   page_consumptions_by_consumption_type,
                   page_video_views,
                   page_positive_feedback_by_type")



fbins_page_monthly <- function(start_date, until_date, page_access_token, page_account){
  
  # Paste together URL
  api_version <- api_version
  url_stem <- "https://graph.facebook.com/"
  URL <- paste0(url_stem, api_version, "/", page_account, "/insights")
  
  # Call insights
  content_result <- content(GET
                            (URL,
                              query = list(
                                metric = metrics_page,
                                period = "month",
                                access_token = page_access_token,
                                since = start_date,
                                until = until_date),
                              encode = "json",
                              verbose()))
  
  # Create df with extracted date range
  result_df <- data.frame(content_result$data[[1]][["values"]] %>%
                            reduce(bind_rows)) %>%
    select("end_time")
  
  # Loop through, extract and bind to date only frame
  for (i in seq_along(content_result$data)){
    result_temp <- data.frame()
    if (is.list(content_result$data[[i]]$values[[1]]$value)) {
      result_temp <- data.frame(content_result$data[[i]]$values[[1]]$value) %>%
        bind_cols(tibble(end_time=content_result$data[[i]]$values[[1]]$end_time))
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
  
  # Remove "other"
  if ("other" %in% colnames(result_df)) {
    result_df <- result_df %>% 
      select(-other)
  }
  
  # Check for values for these metrics, if none - create an empty column
  page_positive_feedback_by_type <- c("link.clicks", "other.clicks", "photo.view", "video.play", "link", "like", "comment")

  for (i in seq_along(page_positive_feedback_by_type)) {
    if (!(page_positive_feedback_by_type[i] %in% colnames(result_df))) {
      result_df <- result_df %>% mutate(!!page_positive_feedback_by_type[i] := NA)
    }
  } 
  
  # Add a total reactions column, rename some metrics and assure consistent order 
  result_df <- result_df %>%
    mutate(reactions = (page_actions_post_reactions_like_total + 
                          page_actions_post_reactions_love_total + 
                          page_actions_post_reactions_wow_total +
                          page_actions_post_reactions_haha_total +
                          page_actions_post_reactions_sorry_total +
                          page_actions_post_reactions_anger_total)) %>%
    mutate(date = (date - 1)) %>%
    rename_with(~ str_replace(.,"\\.", "_")) %>%
    rename_with(~ str_replace(.,"_v2", "")) %>% 
    rename(shares = link) %>%
    relocate(link_clicks, other_clicks, photo_view, video_play, shares, like, comment, .after = page_actions_post_reactions_anger_total)
}


fbins_posts <- function(start_date, until_date, page_access_token, page_account){
  # Paste together URL
  api_version <- api_version
  url_stem <- "https://graph.facebook.com/"
  URL <- paste0(url_stem, api_version, "/", page_account, "/posts")
  
  # Call insights
  content_eng <- content(GET
                         (URL,
                           query = list(
                             fields = fields_post_eng,
                             access_token = page_access_token,
                             since = start_date,
                             until = until_date,
                             limit = 100),
                           encode = "json",
                           verbose()))
  
  # Create a data frame, check for values for the metrics, if none - create empty columns
  content_eng <- as.data.frame(do.call(cbind, content_eng)) %>% 
    select(-paging) %>% 
    unnest_wider(data)
  
  if ("reactions" %in% colnames(content_eng)) {
    content_eng <- content_eng %>%
      unnest_wider(reactions) %>%
      unnest_wider(summary) %>%
      rename(reactions = total_count)
  } else {
    content_eng <- content_eng %>%
      mutate(reactions = NA)
  }
  
  if ("shares" %in% colnames(content_eng)) {
    content_eng <- content_eng %>%
      unnest_wider(shares) %>%
      rename(shares = count) %>%
      select(message, reactions, comments, shares)
  } else {
    content_eng <- content_eng %>%
      mutate(shares = NA) %>%
      select(message, reactions, comments, shares)
  }
  
  if ("comments" %in% colnames(content_eng)) {
    content_eng <- content_eng %>%
      unnest_wider(comments) %>%
      unnest_wider(summary) %>%
      rename(comments = total_count) %>%
      select(message, reactions, comments, shares) %>%
      mutate(message = unlist(message))
  } else {
    content_eng <- content_eng %>%
      mutate(comments = NA) %>%
      select(message, reactions, comments, shares) %>%
      mutate(message = unlist(message))
  }
  
  # Call insights for the other metrics
  content_ins <- content(GET
                         (URL,
                           query = list(
                             fields = fields_post_ins,
                             access_token = page_access_token,
                             since = start_date,
                             until = until_date,
                             limit = 100),
                           encode = "json",
                           verbose()))
  
  post_clicks_by_type_list <- c("other clicks", "video play", "link clicks", "photo view")
  
 for (i in seq_along(content_ins$data)) {
   for(j in seq_along(post_clicks_by_type_list)) {
     if (!post_clicks_by_type_list[j] %in% names(content_ins[["data"]][[i]][["insights"]][["data"]][[10]][["values"]][[1]][["value"]])) {
       content_ins[["data"]][[i]][["insights"]][["data"]][[10]][["values"]][[1]][["value"]][post_clicks_by_type_list[j]] <- NA
     }
   }
 }
  
 # Create data frame 
 content_ins <- map_df(content_ins$data, data.frame) 

 # Check for these metrics, remove them if present  
 targeting_metrics <- c("insights.data.other.clicks", "insights.data.photo.view", "insights.data.video.play", "insights.data.link.clicks")

 for (i in seq_along(targeting_metrics)) {   
  if (targeting_metrics[i] %in% colnames(content_ins)) {
    content_ins <- content_ins %>% 
      select(-targeting_metrics[i])
  }
 }
 
 # Rename metrics, trim Post ID,  
 content_ins <- content_ins %>%
    rename(post_ID = id) %>%
    rename_with(~ str_remove(.,"insights.data.")) %>%
    rename_with(~ str_remove(.,"values.value.")) %>%
    rename_with(~ str_replace(.,"\\.", "_"))%>%
    select(-matches("^id.*|period|description|title|insights_paging", ignore.case = FALSE)) %>%
    mutate(post_ID = str_remove(post_ID, "^[0-9]*_")) %>% 
    pivot_wider(names_from = name, values_from = value)  
    
    
 # Rename metrics      
    for (i in seq_along(n_metrics)) {
      content_ins <- content_ins %>% 
           pivot_wider(names_from = paste("name", n_metrics[i], sep = "_"),  values_from =  paste("value", n_metrics[i], sep = "_"))
    }
    
  # Assure consistent order  
  content_ins <- content_ins %>% 
    select(-matches("name")) %>%
    select(message,	created_time,	full_picture,	permalink_url,	post_impressions,	post_impressions_organic,	post_impressions_paid,	post_impressions_viral,	post_impressions_unique,	post_impressions_organic_unique,	post_impressions_paid_unique,	post_impressions_viral_unique,	post_engaged_users,	photo_view,	link_clicks,	other_clicks,	video_play,	post_ID)
  
  # Merge the two data frames
  content_eng <- merge(content_eng, content_ins, by = "message") 
  
  # Trim the date column
  content_eng <- content_eng %>%
    mutate(created_time=ymd(substr(created_time, start = 1, stop = 10)))
   
}  


fbins_page_fans_city <- function(start_date, until_date, page_access_token, page_account){
  # Paste together URL
  api_version <- api_version
  url_stem <- "https://graph.facebook.com/"
  URL <- paste0(url_stem, api_version, "/", page_account, "/insights")
  
  # Call insights
  content_result <- content(GET
                            (URL,
                              query = list(
                                metric = "page_fans_city",
                                period = "day",
                                access_token = page_access_token,
                                since = start_date,
                                until = until_date),
                              encode = "json",
                              verbose()))
  
  # Create data frame, rename columns
  content_result <- as.data.frame((do.call(rbind, content_result$data[[1]]$values[[1]]$value))) %>%
         rename(page_likes = V1) %>%
         rownames_to_column("city")
}


fbins_page_fans_age_gender <- function(start_date, until_date, page_access_token, page_account){
  # Paste together URL
  api_version <- api_version
  url_stem <- "https://graph.facebook.com/"
  URL <- paste0(url_stem, api_version, "/", page_account, "/insights")
  
  # Call insights
  content_result <- content(GET
                            (URL,
                              query = list(
                                metric = "page_fans_gender_age",
                                period = "day",
                                access_token = page_access_token,
                                since = start_date,
                                until = until_date),
                              encode = "json",
                              verbose()))
  
  # Create data frame, rename columns, separate age and gender into two columns
  content_result <- as.data.frame((do.call(rbind, content_result$data[[1]]$values[[1]]$value))) %>%
    rename(page_likes = V1) %>%
    rownames_to_column("gender_age") %>%
    separate(gender_age, c("gender", "age"), sep = "\\.") %>%
    mutate(gender = recode(gender, U = 'Unknown', M = 'Male', F =  'Female'))
}


fbins_page_daily <- function(start_date, until_date, page_access_token, page_account){
  # Paste together URL
  api_version <- api_version
  url_stem <- "https://graph.facebook.com/"
  URL <- paste0(url_stem, api_version, "/", page_account, "/insights")
  
  # Call insights
  content_result <- content(GET
                            (URL,
                              query = list(
                                metric = metrics_page,
                                period = "day",
                                access_token = page_access_token,
                                since = start_date,
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
    select(ncol(result_df), 1:ncol(result_df)) %>%
    mutate(date = (date - 1))
  
  # Remove "other"
  if ("other" %in% colnames(result_df)) {
    result_df <- result_df %>% 
      select(-other)
  }
  
  # Remove "page_fans"
  if ("page_fans" %in% colnames(result_df)) {
    result_df <- result_df %>% 
      select(-page_fans)
  }
  
  # Check for values for this metrics, if none - create an empty column
  page_positive_feedback_by_type_daily <- c("link clicks", "other clicks", "photo view", "video play", "link", "like", "comment")
  
  for (i in seq_along(page_positive_feedback_by_type_daily)) {
    if (!(page_positive_feedback_by_type_daily[i] %in% colnames(result_df))) {
      result_df <- result_df %>% mutate(!!page_positive_feedback_by_type_daily[i] := NA)
    }
  } 
  
  # Rename metrics and assure consistent order of columns
  result_df <- result_df %>%
    rename(shares = link) %>%
    rename_with(~ str_replace(.," ", "_")) %>%
    rename_with(~ str_replace(.,"_v2", "")) %>% 
    relocate(page_engaged_users, page_post_engagements, page_impressions,	page_impressions_unique,	page_impressions_paid,	page_impressions_paid_unique,	page_impressions_organic,	page_impressions_organic_unique,	page_impressions_viral,	page_impressions_viral_unique,	page_fan_adds,	page_fan_removes,	page_actions_post_reactions_like_total,	page_actions_post_reactions_love_total,	page_actions_post_reactions_wow_total,	page_actions_post_reactions_haha_total,	page_actions_post_reactions_sorry_total,	page_actions_post_reactions_anger_total,	link_clicks,	other_clicks,	photo_view,	video_play,	shares,	like,	comment,	page_video_views) 
}
