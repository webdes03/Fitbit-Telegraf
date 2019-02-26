#!/bin/bash

# ----------------------------------------------------------------------------------
# Fitbit App Configuration
clientid="xxxxxx" # OAuth 2.0 Client ID
clientsecret="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # Client Secret
callbackurl="https://mike-greene.com" # Callback URL

# Fitbit Access Token
code="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Fitbit Units
units="en_US"

today=$(date -d "00:00 today" +"%Y-%m-%d") # Today's date, formatted for Fitbit API calls (YYYY-MM-DD)
yesterday=$(date -d "00:00 today" +"%Y-%m-%d") # Yesterday's date, formatted for Fitbit API calls (YYYY-MM-DD)
sevenDaysAgo=$(date -d "00:00 7 days ago" +"%Y-%m-%d") # Seven days ago date, formatted for Fitbit API calls (YYYY-MM-DD)

# Global tags for influxdb
globalTags="platform=Fitbit"

# Path to folder containing this script
cd /var/scripts/fitbit
# ----------------------------------------------------------------------------------