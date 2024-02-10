# Load packages
library(rfacebookstat)
library(tidyverse)
library(lubridate)
library(googlesheets4)

username <- "<USER_NAME>"
app_id <- "<APP_ID>"
app_secret <- "<APP_SECRET>"
api_version <- "<API_VERSION>"
fields <- c("campaign_name, campaign_id, adset_name, adset_id, ad_name, ad_id, impressions, reach, clicks, spend, actions, optimization_goal, objective, estimated_ad_recallers, cost_per_thruplay")
actions <-c("link_click", "like", "post", "comment", "photo_view","post_reaction", "rsvp", "video_view", "click_to_call_call_confirm", "call_confirm_grouped", "onsite_conversion.lead_grouped", "leadgen_grouped","onsite_conversion.post_save", "estimated_ad_recallers", "cost_per_thruplay")

# Get daily data

fb_ads_daily <- function(account_id, date_start, date_stop) {
  # Get the results from the Facebook API 
  result <- fbGetMarketingStat(account_id = account_id, 
                               level = "ad", 
                               breakdowns = "age, gender",
                               date_start = date_start,
                               date_stop = date_stop,
                               fields = fields,
                               action_report_time = "impression",
                               use_account_attribution_setting = TRUE,
                               api_version = api_version,
                               username = username)
  
  Sys.sleep(15)

  thruplays <- fbGetMarketingStat(account_id = account_id, 
                                  level = "ad", 
                                  breakdowns = "age, gender",
                                  date_start = date_start,
                                  date_stop = date_stop,
                                  fields = "ad_id, cost_per_thruplay",
                                  action_report_time = "impression",
                                  use_account_attribution_setting = TRUE,
                                  api_version = api_version,
                                  username = username)
  
  result <- left_join(result, thruplays)
  
  # Make sure that all columns are present even if there are no values for the selected time period
  for (i in seq_along(actions)) {
    if (!(actions[i] %in% colnames(result))) {
      result <- result %>% mutate(!!actions[i] := NA)
    }
  }
  
  # Reorder columns to have consistent structure every time, set appropriate data types, rename some metrics 
  result <- result %>% 
    select(campaign_name, campaign_id, adset_name, adset_id, ad_name, ad_id, impressions, reach, clicks, spend, date_start, date_stop, age, gender, link_click, post_reaction, onsite_conversion.post_save, post_engagement, page_engagement, post, like, video_view, comment, rsvp, photo_view, click_to_call_call_confirm, call_confirm_grouped, onsite_conversion.lead_grouped, leadgen_grouped, optimization_goal, objective, estimated_ad_recallers, cost_per_thruplay) %>%
    mutate_at(vars(-c(campaign_name, campaign_id, adset_name, adset_id, ad_name, ad_id, age, gender, date_start, date_stop, optimization_goal, objective)), as.numeric) %>%
    mutate_at(vars(c(date_start, date_stop)), as.Date) %>%
    rename(page_like = like,
           share = post,
           event_response = rsvp) %>% 
    mutate(thruplays = round(spend/cost_per_thruplay)) 
}

# Get monthly data

fb_ads_monthly <- function(account_id, date_start, date_stop) {
  # Get the results from the Facebook API 
  result <- fbGetMarketingStat(account_id = account_id, 
                               level = "ad", 
                               breakdowns = "age, gender",
                               date_start = date_start,
                               date_stop = date_stop,
                               fields = fields,
                               action_report_time = "impression", interval = "monthly",
                               use_account_attribution_setting = TRUE,
                               api_version = api_version,
                               username = username)
  
  Sys.sleep(10)

  thruplays <- fbGetMarketingStat(account_id = account_id, 
                                  level = "ad", 
                                  breakdowns = "age, gender",
                                  date_start = date_start,
                                  date_stop = date_stop,
                                  fields = "ad_id, cost_per_thruplay",
                                  action_report_time = "impression", interval = "monthly",
                                  use_account_attribution_setting = TRUE,
                                  api_version = api_version,
                                  username = username)
  
  result <- left_join(result, thruplays)
  
  # Make sure that all columns are present even if there are no values for the selected time period
  for (i in seq_along(actions)) {
    if (!(actions[i] %in% colnames(result))) {
      result <- result %>% mutate(!!actions[i] := NA)
    }
  }
  
  # Reorder columns to have consistent structure every time, set appropriate data types, rename some metrics 
  result <- result %>% 
    select(campaign_name, campaign_id, adset_name, adset_id, ad_name, ad_id, impressions, reach, clicks, spend, date_start, date_stop, age, gender, link_click, post_reaction, onsite_conversion.post_save, post_engagement, page_engagement, post, like, video_view, comment, rsvp, photo_view, click_to_call_call_confirm, call_confirm_grouped, onsite_conversion.lead_grouped, leadgen_grouped, optimization_goal, objective, estimated_ad_recallers, cost_per_thruplay) %>%
    mutate_at(vars(-c(campaign_name, campaign_id, adset_name, adset_id, ad_name, ad_id, age, gender, date_start, date_stop, optimization_goal, objective)), as.numeric) %>%
    mutate_at(vars(c(date_start, date_stop)), as.Date) %>%
    rename(page_like = like,
           share = post,
           event_response = rsvp) %>% 
    mutate(thruplays = round(spend/cost_per_thruplay)) 
}

# Get daily data for a whole month 

fb_ads_monthly_by_day <- function(account_id, date_start, date_stop) {
  # Get the results from the Facebook API 
  result <- fbGetMarketingStat(account_id = account_id, 
                               level = "ad", 
                               breakdowns = "age, gender",
                               date_start = date_start,
                               date_stop = date_stop,
                               fetch_by = "day",
                               fields = fields,
                               action_report_time = "impression", interval = "monthly",
                               use_account_attribution_setting = TRUE,
                               api_version = api_version,
                               username = username)
  
  Sys.sleep(10)
  
  thruplays <- fbGetMarketingStat(account_id = account_id, 
                                  level = "ad", 
                                  breakdowns = "age, gender",
                                  date_start = date_start,
                                  date_stop = date_stop,
                                  fetch_by = "day",
                                  fields = "ad_id, cost_per_thruplay",
                                  action_report_time = "impression", interval = "monthly",
                                  use_account_attribution_setting = TRUE,
                                  api_version = api_version,
                                  username = username)
  
  result <- left_join(result, thruplays)
  
  # Make sure that all columns are present even if there are no values for the selected time period
  for (i in seq_along(actions)) {
    if (!(actions[i] %in% colnames(result))) {
      result <- result %>% mutate(!!actions[i] := NA)
    }
  }
  
  # Reorder columns to have consistent structure every time, set appropriate data types, rename some metrics 
  result <- result %>% 
    select(campaign_name, campaign_id, adset_name, adset_id, ad_name, ad_id, impressions, reach, clicks, spend, date_start, date_stop, age, gender, link_click, post_reaction, onsite_conversion.post_save, post_engagement, page_engagement, post, like, video_view, comment, rsvp, photo_view, click_to_call_call_confirm, call_confirm_grouped, onsite_conversion.lead_grouped, leadgen_grouped, optimization_goal, objective, estimated_ad_recallers, cost_per_thruplay) %>%
    mutate_at(vars(-c(campaign_name, campaign_id, adset_name, adset_id, ad_name, ad_id, age, gender, date_start, date_stop, optimization_goal, objective)), as.numeric) %>%
    mutate_at(vars(c(date_start, date_stop)), as.Date) %>%
    rename(page_like = like,
           share = post,
           event_response = rsvp) %>% 
    mutate(thruplays = round(spend/cost_per_thruplay)) 
}

# Get data for yesterday 

fb_ads_yesterday <- function(account_id) {
  # Get the results from the Facebook API 
  result <- fbGetMarketingStat(account_id = account_id, 
                               level = "ad", 
                               breakdowns = "age, gender",
                               date_preset = "yesterday",
                               fields = fields,
                               action_report_time = "impression",
                               use_account_attribution_setting = TRUE,
                               api_version = api_version,
                               username = username)
  
  Sys.sleep(10)
  
  thruplays <- fbGetMarketingStat(account_id = account_id, 
                                  level = "ad", 
                                  breakdowns = "age, gender",
                                  date_preset = "yesterday",
                                  fields = "ad_id, cost_per_thruplay",
                                  action_report_time = "impression",
                                  use_account_attribution_setting = TRUE,
                                  api_version = api_version,
                                  username = username)
  
  result <- left_join(result, thruplays)
  
  # Make sure that all columns are present even if there are no values for the selected time period
  for (i in seq_along(actions)) {
    if (!(actions[i] %in% colnames(result))) {
      result <- result %>% mutate(!!actions[i] := NA)
    }
  }
  
  # Reorder columns to have consistent structure every time, set appropriate data types, rename some metrics 
  result <- result %>% 
    select(campaign_name, campaign_id, adset_name, adset_id, ad_name, ad_id, impressions, reach, clicks, spend, date_start, date_stop, age, gender, link_click, post_reaction, onsite_conversion.post_save, post_engagement, page_engagement, post, like, video_view, comment, rsvp, photo_view, click_to_call_call_confirm, call_confirm_grouped, onsite_conversion.lead_grouped, leadgen_grouped, optimization_goal, objective, estimated_ad_recallers, cost_per_thruplay) %>%
    mutate_at(vars(-c(campaign_name, campaign_id, adset_name, adset_id, ad_name, ad_id, age, gender, date_start, date_stop, optimization_goal, objective)), as.numeric) %>%
    mutate_at(vars(c(date_start, date_stop)), as.Date) %>%
    rename(page_like = like,
           share = post,
           event_response = rsvp) %>% 
    mutate(thruplays = round(spend/cost_per_thruplay)) 
}
