# About The Project

This is a real-world solution that I have built for my current job (at a digital marketing agency) that we have been using for over a year now. It gets data about the performance of our clients' social media channels. The data is then used to build dashboards and reports in Looker Studio. I've made an example dashboard in Tableau that could be explored [here.](https://public.tableau.com/views/SocialMediaPerformanceDashboard_17052315409930/SOCIALMEDIAPERFORMANCE?:language=en-US&:display_count=n&:origin=viz_share_link "Social Media Performance Dashboard")

# Description of the Problem

As previously stated we use Looker Studio for visualization. The platform is owned by Google so it offers free integration with marketing tools such as Google Ads and Google Analytics. However, to include data from social media channels you should either manually extract the data into Google Sheets, which is extremely time-consuming when you have to do it for over 100 clients, or use third-party connectors such as Supermetrics, which are easy to use but have high fees when used for multiple accounts.

# Solution

I've built an R script that connects to the platforms' APIs, collects the data, and saves it into Google Sheets which can be easily connected to Looker Studio (or other tools) for visualizations. The functions and the data they gather are tailored to the agency's needs but could be easily customized to your liking.

# How to use

## Prerequisites

### Accessing the Facebook Marketing API

Accessing the Facebook Marketing API involves a series of steps from setting up a Facebook Developer account to creating an app and configuring it for Marketing API access. Follow this guide to get started.

### Step 1: Create a Facebook Developer Account

1.  **Sign Up:** Create a Facebook account if you don't already have one.
2.  **Developer Account:** Visit the [Facebook for Developers](https://developers.facebook.com/) website and sign up for a developer account using your Facebook credentials.

### Step 2: Create a New App

-   **Create App:** In the Facebook for Developers portal, create a new app. Choose the app type that fits your use case (e.g., Business, Consumer).
-   **App Details:** Follow the prompts, providing necessary details like app name and contact email.

### Step 3: Add the Marketing API

-   **Add Product:** In your app's dashboard, find the "+ Add Product" section. Locate the Marketing API and set it up.

### Step 4: Configure Your App Settings

-   **Settings:** Fill in your app details, including its use case and how it will interact with the Marketing API.
-   **Configure:** Add platforms (website, iOS, Android), set up privacy policies, etc.

### Step 5: Generate Access Tokens

-   **Access Tokens:** Navigate to "Tools & Support" and use the "Access Token Tool" or the Graph API Explorer to generate tokens.
-   **Token Type:** Use a development token for testing, but you'll need a long-lived token for production.

### Step 6: Review Permissions and Features

-   **Permissions:** The Marketing API requires permissions such as `ads_management`, `ads_read`, etc., depending on your needs.
-   **Configure Permissions:** Ensure your app requests all necessary permissions.

### Additional Considerations

-   **Stay Updated:** Meta updates its API and policies periodically. Regularly check the [Facebook for Developers Blog](https://developers.facebook.com/blog/) and documentation.
-   **Security:** Keep access tokens secure and follow best security practices for your app.

### Accessing the LinkedIn Marketing API

To use the LinkedIn Marketing API, you need to follow a series of steps, similarly to the ones for Meta. This guide will walk you through the process.

### Step 1: Create a LinkedIn Developer Account

1.  **LinkedIn Account:** Ensure you have a LinkedIn account. Sign up on [LinkedIn](https://www.linkedin.com/) if you don't have one.
2.  **Developer Portal:** Visit the [LinkedIn Developer Portal](https://www.linkedin.com/developers/) and sign in with your LinkedIn credentials.

### Step 2: Create a New Application

-   **New App:** Click on the "Create App" button.
-   **App Details:** Fill in the application details, including Company, Name, Description, and Privacy Policy URL. You will also need to upload a logo.

### Step 3: Configure Your Application

-   **Products:** Select the Marketing Developer Platform product to add to your app.
-   **Permissions:** Request the necessary permissions for your application, such as `r_ads`, `r_ads_reporting`, `w_ads`, etc.

### Step 4: Generate Auth Credentials

-   **Auth Keys:** Navigate to the "Auth" section of your app settings to find your Client ID and Client Secret.
-   **Redirect URLs:** Add the OAuth 2.0 redirect URLs for your application.

### Step 5: Implement OAuth 2.0 Authentication

-   **Authorization Code Flow:** Implement the OAuth 2.0 authorization code flow to obtain access tokens for making API calls.
-   **Documentation:** Refer to LinkedIn's [OAuth 2.0 Guide](https://docs.microsoft.com/en-us/linkedin/shared/authentication/authorization-code-flow) for detailed steps.

### Additional Tips

-   **Stay Updated:** LinkedIn periodically updates its APIs. Keep an eye on the [LinkedIn Developer Blog](https://blog.linkedin.com/) for announcements and updates.
-   **Security Best Practices:** Securely store your Client Secret and access tokens. Follow LinkedIn's recommendations for secure API use.

## Using the script

### In the get-tokens-and-ids folders there are some helper functions:

-   get-fb-pages-access-tokens - If you have multiple Facebook pages that you want to get data for, you can use this script to generate an access token for each page.

-   get-linkedin-token - Does exactly what it says - generates an access token that you could use to get data for your ad accounts.

### Main functions

#### fb-ads

It leverages the [rfacebookstat](https://selesnow.github.io/rfacebookstat//) package made by Alexey Seleznev. I've made some wrapper functions to tailor it to our needs. Here are the functions and their purpose:

-   f**b_ads_daily** - Gets daily data for all campaigns in a given account. The data is broken down by age and gender. It takes 3 arguments: account_id, date_start, date_stop.

-   **fb_ads_monthly** - Does the same as fb_ads_daily but gets data for a whole month. It takes 3 arguments: account_id, date_start, date_stop

-   **fb_ads_monthly_by_day** - Gets monthly data broken down by date, age and gender. It takes 3 arguments: account_id, date_start, date_stop

-   **fb_ads_yesterday** - Gets data for yesterday. The data is broken down by age and gender. It takes 3 arguments: account_id, date_start, date_stop.

#### fb-ads-creatives

It has one function that gathers the creative elements of each ad in the given ad accounts:

-   **fb_get_creatives** - It takes just one argument - account_id

Its results can be joined with the results from the fb-ads functions to get the results for each creative.

#### fb-insights

It gathers data for a Facebook Page, represented in the functions with its ID and access token and has the following functions.

-   f**bins_page_monthly** - Gets monthly data. It takes 4 arguments: start_date, until_date, page_access_token, page_account.

-   **fbins_page_daily** - Gets daily data. Takes 4 arguments: start_date, until_date, page_access_token, page_account.

-   **fbins_posts** - Gets data about the posts from the page. It takes 4 arguments: start_date, until_date, page_access_token, page_account.

-   **fbins_page_fans_city** - Gets the number of page likes broken down by city. It takes 4 arguments: start_date, until_date, page_access_token, page_account.

-   **fbins_page_fans_age_gender** - Gets the number of page likes broken down by age and gender. It takes 4 arguments: start_date, until_date, page_access_token, page_account.

#### ig-insights

It gathers data for an Instagram Business Profile, represented in the functions with its ID and has the following functions:

-   **igins_page_daily** - It gets daily data. Takes the following arguments: since_date, until_date, access_token, page_account. For Instagram the access token is an user access token.

-   **igins_followers** - Gets the number of followers of the profile. Takes the following arguments: access_token, page_account.

-   **igins_reach** - Gets the reach of the profile for 28 days from a given date. Takes the following arguments: until_date, access_token, page_account.

-   **igins_posts** - Gets data about the posts from the profile. It takes the following arguments: start_date, until_date, access_token, page_account.

-   **igins_city** - Gets the number of followers broken down by city. Takes the following arguments: access_token, page_account.

-   **igins_age_gender** - Gets the number of followers broken down by age and gender. Takes the following arguments: access_token, page_account.

#### linkedin-ads

It gathers data about all campaigns in a given account. It contains one function:

-   **linkedin_ads_daily** - Gets data about the performance of all campaigns in a given account broken down by day. Takes the following arguments: date_start, date_end, account_id, access_token.
