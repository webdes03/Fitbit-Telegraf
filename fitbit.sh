#!/bin/bash

# ----------------------------------------------------------------------------------
# Fitbit Configuration obtained from your app at: https://dev.fitbit.com/apps
clientid="xxxxxx" #OAuth 2.0 Client ID
clientsecret="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" #Client Secret
callbackurl="https://mike-greene.com" #Callback URL, eg: https://domoticz.com

# Fitbit Configuration obtained from the browser redirect
code="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Fitbit Configuration set your units
units="en_US" #Options are: Metric, en_US, en_GB

today=$(date -d "00:00 today" +"%Y-%m-%d")
yesterday=$(date -d "00:00 today" +"%Y-%m-%d")
sevenDaysAgo=$(date -d "00:00 7 days ago" +"%Y-%m-%d")

# Global tags for influxdb
globalTags="platform=Fitbit"

# Path to folder containing this script
cd /var/scripts/fitbit
# ----------------------------------------------------------------------------------

# Create fitbit basic auth token
basicauthtoken=$(echo -n "${clientid}:${clientsecret}" | openssl base64)

# Get a Fitbit oauth2 token
refreshtoken=$(cat refreshtoken.txt 2> /dev/null)
# If we already have a stored token, get a new one.
if [ ! -f refreshtoken.txt ]; then
#echo "Getting access token for the first time..."
oauth=$(curl --max-time 60 -s -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Basic ${basicauthtoken}" "https://api.fitbit.com/oauth2/token?client_id=${clientid}&grant_type=authorization_code&redirect_uri=${callbackurl}&code=${code}")
else
#echo "Detected existing refresh token, getting a new access token..."
oauth=$(curl --max-time 60 -s -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Authorization: Basic ${basicauthtoken}" "https://api.fitbit.com/oauth2/token?client_id=${clientid}&grant_type=refresh_token&refresh_token=${refreshtoken}")
fi

# Put oauth2 token into easy to use variables and store the refresh token
accesstoken=$(echo "$oauth" | jq ".access_token" | sed 's/["]*//g')
newrefreshtoken=$(echo "$oauth" | jq ".refresh_token" | sed 's/["]*//g')
echo "$newrefreshtoken" > refreshtoken.txt

echo -n "" > fitbit.txt

# Get profile from Fitbit
getProfile=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1/user/-/profile.json")
echo -e "$getProfile" >> fitbit.txt

# Get data from Fitbit
getWeight=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1/user/-/body/log/weight/date/${today}/7d.json")
getSteps=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1/user/-/activities/steps/date/${today}/7d.json")
getDistance=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1/user/-/activities/distance/date/${today}/7d.json")
getFloors=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1/user/-/activities/floors/date/${today}/7d.json")
getMinutesSedentary=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1/user/-/activities/minutesSedentary/date/${today}/7d.json")
getMinutesLightlyActive=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1/user/-/activities/minutesLightlyActive/date/${today}/7d.json")
getMinutesFairlyActive=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1/user/-/activities/minutesFairlyActive/date/${today}/7d.json")
getMinutesVeryActive=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1/user/-/activities/minutesVeryActive/date/${today}/7d.json")
getCalories=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1/user/-/activities/calories/date/${today}/7d.json")
getSleep=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1.2/user/-/sleep/date/${sevenDaysAgo}/${today}.json")
getHeartrate=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1/user/-/activities/heart/date/${today}/7d.json")

# Get UTC offset for user
userOffsetFromUTCMillis=$(echo "$getProfile" | jq ".user.offsetFromUTCMillis")

# Weight
#echo -e "$getWeight" >> fitbit.txt
for row in $(echo "${getWeight}" | jq -r '.weight[] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    measurementDate=$(echo $(_jq '.date'))
    measurementTime=$(echo $(_jq '.time'))
    measurementFullDate="${measurementDate} ${measurementTime} UTC"
    measurementTS=$(date --date "${measurementDate}" +%s)
    measurementCorrectedTS=$((((measurementTS - $((userOffsetFromUTCMillis / 1000)))) * 1000000000))

    dateTodayShortDay=$(date --date "${measurementFullDate}" +%a)
    dateTodayLongDay=$(date --date "${measurementFullDate}" +%A)
    tags="${globalTags},shortDay=${dateTodayShortDay},longDay=${dateTodayLongDay}"

    weight=$(echo $(_jq '.weight'))
    bmi=$(echo $(_jq '.bmi'))
    fat=$(echo $(_jq '.fat'))

    echo -e "weight,$tags weight=$weight $measurementCorrectedTS" >> fitbit.txt
    echo -e "weight,$tags bmi=$bmi$measurementCorrectedTS" >> fitbit.txt
    echo -e "weight,$tags fat=$fat $measurementCorrectedTS" >> fitbit.txt

    echo -e "weight,${tags} weight=${weight} $measurementCorrectedTS"
    echo -e "weight,${tags} bmi=${bmi} $measurementCorrectedTS"
    echo -e "weight,${tags} fat=${fat} $measurementCorrectedTS"
done

# Steps
#echo -e "$getSteps" >> fitbit.txt
for row in $(echo "${getSteps}" | jq -r '.["activities-steps"][] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    measurementDate=$(echo $(_jq '.dateTime'))
    measurementFullDate="${measurementDate} 0000 UTC"
    measurementTS=$(date --date "${measurementDate}" +%s)
    measurementCorrectedTS=$((((measurementTS - $((userOffsetFromUTCMillis / 1000)))) * 1000000000))

    dateTodayShortDay=$(date --date "${measurementFullDate}" +%a)
    dateTodayLongDay=$(date --date "${measurementFullDate}" +%A)
    tags="${globalTags},shortDay=${dateTodayShortDay},longDay=${dateTodayLongDay}"

    steps=$(echo $(_jq '.value'))

    echo -e "activity,$tags steps=$steps $measurementCorrectedTS" >> fitbit.txt

    echo -e "activity,${tags} steps=${steps} $measurementCorrectedTS"
done

# Calories
#echo -e "$getCalories" >> fitbit.txt
for row in $(echo "${getCalories}" | jq -r '.["activities-calories"][] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    measurementDate=$(echo $(_jq '.dateTime'))
    measurementFullDate="${measurementDate} 0000 UTC"
    measurementTS=$(date --date "${measurementDate}" +%s)
    measurementCorrectedTS=$((((measurementTS - $((userOffsetFromUTCMillis / 1000)))) * 1000000000))

    dateTodayShortDay=$(date --date "${measurementFullDate}" +%a)
    dateTodayLongDay=$(date --date "${measurementFullDate}" +%A)
    tags="${globalTags},shortDay=${dateTodayShortDay},longDay=${dateTodayLongDay}"

    calories=$(echo $(_jq '.value'))

    echo -e "activity,$tags calories=$calories $measurementCorrectedTS" >> fitbit.txt

    echo -e "activity,${tags} calories=${calories} $measurementCorrectedTS"
done

# Distance
#echo -e "$getDistance" >> fitbit.txt
for row in $(echo "${getDistance}" | jq -r '.["activities-distance"][] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    measurementDate=$(echo $(_jq '.dateTime'))
    measurementFullDate="${measurementDate} 0000 UTC"
    measurementTS=$(date --date "${measurementDate}" +%s)
    measurementCorrectedTS=$((((measurementTS - $((userOffsetFromUTCMillis / 1000)))) * 1000000000))

    dateTodayShortDay=$(date --date "${measurementFullDate}" +%a)
    dateTodayLongDay=$(date --date "${measurementFullDate}" +%A)
    tags="${globalTags},shortDay=${dateTodayShortDay},longDay=${dateTodayLongDay}"

    distance=$(echo $(_jq '.value'))

    echo -e "activity,$tags distance=$distance $measurementCorrectedTS" >> fitbit.txt

    echo -e "activity,${tags} distance=${distance} $measurementCorrectedTS"
done

# Floors
#echo -e "$getFloors" >> fitbit.txt
for row in $(echo "${getFloors}" | jq -r '.["activities-floors"][] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    measurementDate=$(echo $(_jq '.dateTime'))
    measurementFullDate="${measurementDate} 0000 UTC"
    measurementTS=$(date --date "${measurementDate}" +%s)
    measurementCorrectedTS=$((((measurementTS - $((userOffsetFromUTCMillis / 1000)))) * 1000000000))

    dateTodayShortDay=$(date --date "${measurementFullDate}" +%a)
    dateTodayLongDay=$(date --date "${measurementFullDate}" +%A)
    tags="${globalTags},shortDay=${dateTodayShortDay},longDay=${dateTodayLongDay}"

    floors=$(echo $(_jq '.value'))

    echo -e "activity,$tags floors=$floors $measurementCorrectedTS" >> fitbit.txt

    echo -e "activity,${tags} floors=${floors} $measurementCorrectedTS"
done

# Sedentary Minutes
#echo -e "$getMinutesSedentary" >> fitbit.txt
for row in $(echo "${getMinutesSedentary}" | jq -r '.["activities-minutesSedentary"][] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    measurementDate=$(echo $(_jq '.dateTime'))
    measurementFullDate="${measurementDate} 0000 UTC"
    measurementTS=$(date --date "${measurementDate}" +%s)
    measurementCorrectedTS=$((((measurementTS - $((userOffsetFromUTCMillis / 1000)))) * 1000000000))

    dateTodayShortDay=$(date --date "${measurementFullDate}" +%a)
    dateTodayLongDay=$(date --date "${measurementFullDate}" +%A)
    tags="${globalTags},shortDay=${dateTodayShortDay},longDay=${dateTodayLongDay}"

    minutesSedentary=$(echo $(_jq '.value'))

    echo -e "activity,$tags minutesSedentary=$minutesSedentary $measurementCorrectedTS" >> fitbit.txt

    echo -e "activity,${tags} minutesSedentary=${minutesSedentary} $measurementCorrectedTS"
done

# Lightly Active Minutes
#echo -e "$getMinutesLightlyActive" >> fitbit.txt
for row in $(echo "${getMinutesLightlyActive}" | jq -r '.["activities-minutesLightlyActive"][] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    measurementDate=$(echo $(_jq '.dateTime'))
    measurementFullDate="${measurementDate} 0000 UTC"
    measurementTS=$(date --date "${measurementDate}" +%s)
    measurementCorrectedTS=$((((measurementTS - $((userOffsetFromUTCMillis / 1000)))) * 1000000000))

    dateTodayShortDay=$(date --date "${measurementFullDate}" +%a)
    dateTodayLongDay=$(date --date "${measurementFullDate}" +%A)
    tags="${globalTags},shortDay=${dateTodayShortDay},longDay=${dateTodayLongDay}"

    minutesLightlyActive=$(echo $(_jq '.value'))

    echo -e "activity,$tags minutesLightlyActive=$minutesLightlyActive $measurementCorrectedTS" >> fitbit.txt

    echo -e "activity,${tags} minutesLightlyActive=${minutesLightlyActive} $measurementCorrectedTS"
done

# Fairly Active Minutes
#echo -e "$getMinutesFairlyActive" >> fitbit.txt
for row in $(echo "${getMinutesFairlyActive}" | jq -r '.["activities-minutesFairlyActive"][] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    measurementDate=$(echo $(_jq '.dateTime'))
    measurementFullDate="${measurementDate} 0000 UTC"
    measurementTS=$(date --date "${measurementDate}" +%s)
    measurementCorrectedTS=$((((measurementTS - $((userOffsetFromUTCMillis / 1000)))) * 1000000000))

    dateTodayShortDay=$(date --date "${measurementFullDate}" +%a)
    dateTodayLongDay=$(date --date "${measurementFullDate}" +%A)
    tags="${globalTags},shortDay=${dateTodayShortDay},longDay=${dateTodayLongDay}"

    minutesFairlyActive=$(echo $(_jq '.value'))

    echo -e "activity,$tags minutesFairlyActive=$minutesFairlyActive $measurementCorrectedTS" >> fitbit.txt

    echo -e "activity,${tags} minutesFairlyActive=${minutesFairlyActive} $measurementCorrectedTS"
done

# Very Active Minutes
#echo -e "$getMinutesVeryActive" >> fitbit.txt
for row in $(echo "${getMinutesVeryActive}" | jq -r '.["activities-minutesVeryActive"][] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    measurementDate=$(echo $(_jq '.dateTime'))
    measurementFullDate="${measurementDate} 0000 UTC"
    measurementTS=$(date --date "${measurementDate}" +%s)
    measurementCorrectedTS=$((((measurementTS - $((userOffsetFromUTCMillis / 1000)))) * 1000000000))

    dateTodayShortDay=$(date --date "${measurementFullDate}" +%a)
    dateTodayLongDay=$(date --date "${measurementFullDate}" +%A)
    tags="${globalTags},shortDay=${dateTodayShortDay},longDay=${dateTodayLongDay}"

    minutesVeryActive=$(echo $(_jq '.value'))

    echo -e "activity,$tags minutesVeryActive=$minutesVeryActive $measurementCorrectedTS" >> fitbit.txt

    echo -e "activity,${tags} minutesVeryActive=${minutesVeryActive} $measurementCorrectedTS"
done

# Sleep
#echo -e "$getSleep" >> fitbit.txt
for row in $(echo "${getSleep}" | jq -r '.sleep[] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    measurementDate=$(echo $(_jq '.dateOfSleep'))
    measurementFullDate="${measurementDate} 0000 UTC"
    measurementTS=$(date --date "${measurementDate}" +%s)
    measurementCorrectedTS=$((((measurementTS - $((userOffsetFromUTCMillis / 1000)))) * 1000000000))

    dateTodayShortDay=$(date --date "${measurementFullDate}" +%a)
    dateTodayLongDay=$(date --date "${measurementFullDate}" +%A)
    tags="${globalTags},shortDay=${dateTodayShortDay},longDay=${dateTodayLongDay}"

    deepSleepMinutes=$(echo $(_jq '.levels.summary.deep.minutes'))
    lightSleepMinutes=$(echo $(_jq '.levels.summary.light.minutes'))
    remSleepMinutes=$(echo $(_jq '.levels.summary.rem.minutes'))
    wakeMinutes=$(echo $(_jq '.levels.summary.wake.minutes'))
    durationMillis=$(echo $(_jq '.duration'))
    efficiency=$(echo $(_jq '.efficiency'))
    minutesAfterWakeup=$(echo $(_jq '.minutesAfterWakeup'))
    minutesAsleep=$(echo $(_jq '.minutesAsleep'))
    minutesAwake=$(echo $(_jq '.minutesAwake'))
    minutesToFallAsleep=$(echo $(_jq '.minutesToFallAsleep'))
    startTime=$(date --date $(echo $(_jq '.startTime')) +%s)
    timeInBedMinutes=$(echo $(_jq '.timeInBed'))

    if [ -n "$deepSleepMinutes" ]; then
        deepSleepMinutes="0"
    fi

    if [ -n "$lightSleepMinutes" ]; then
        lightSleepMinutes="0"
    fi

    if [ -n "$remSleepMinutes" ]; then
        remSleepMinutes="0"
    fi

    if [ -n "$wakeMinutes" ]; then
        wakeMinutes="0"
    fi

    

    echo -e "sleep,$tags deepSleepMinutes=$deepSleepMinutes $measurementCorrectedTS" >> fitbit.txt
    echo -e "sleep,$tags lightSleepMinutes=$lightSleepMinutes $measurementCorrectedTS" >> fitbit.txt
    echo -e "sleep,$tags remSleepMinutes=$remSleepMinutes $measurementCorrectedTS" >> fitbit.txt
    echo -e "sleep,$tags wakeMinutes=$wakeMinutes $measurementCorrectedTS" >> fitbit.txt
    echo -e "sleep,$tags durationMillis=$durationMillis $measurementCorrectedTS" >> fitbit.txt
    echo -e "sleep,$tags efficiency=$efficiency $measurementCorrectedTS" >> fitbit.txt
    echo -e "sleep,$tags minutesAfterWakeup=$minutesAfterWakeup $measurementCorrectedTS" >> fitbit.txt
    echo -e "sleep,$tags minutesAsleep=$minutesAsleep $measurementCorrectedTS" >> fitbit.txt
    echo -e "sleep,$tags minutesAwake=$minutesAwake $measurementCorrectedTS" >> fitbit.txt
    echo -e "sleep,$tags minutesToFallAsleep=$minutesToFallAsleep $measurementCorrectedTS" >> fitbit.txt
    echo -e "sleep,$tags startTime=$startTime $measurementCorrectedTS" >> fitbit.txt
    echo -e "sleep,$tags timeInBedMinutes=$timeInBedMinutes $measurementCorrectedTS" >> fitbit.txt

    echo -e "sleep,${tags} deepSleepMinutes=${deepSleepMinutes} $measurementCorrectedTS"
    echo -e "sleep,${tags} lightSleepMinutes=${lightSleepMinutes} $measurementCorrectedTS"
    echo -e "sleep,${tags} remSleepMinutes=${remSleepMinutes} $measurementCorrectedTS"
    echo -e "sleep,${tags} wakeMinutes=${wakeMinutes} $measurementCorrectedTS"
    echo -e "sleep,${tags} durationMillis=${durationMillis} $measurementCorrectedTS"
    echo -e "sleep,${tags} efficiency=${efficiency} $measurementCorrectedTS"
    echo -e "sleep,${tags} minutesAfterWakeup=${minutesAfterWakeup} $measurementCorrectedTS"
    echo -e "sleep,${tags} minutesAsleep=${minutesAsleep} $measurementCorrectedTS"
    echo -e "sleep,${tags} minutesAwake=${minutesAwake} $measurementCorrectedTS"
    echo -e "sleep,${tags} minutesToFallAsleep=${minutesToFallAsleep} $measurementCorrectedTS"
    echo -e "sleep,${tags} startTime=${startTime} $measurementCorrectedTS"
    echo -e "sleep,${tags} timeInBedMinutes=${timeInBedMinutes} $measurementCorrectedTS"
done

# Heartrate
#echo -e "$getHeartrate" >> fitbit.txt
for row in $(echo "${getHeartrate}" | jq -r '.["activities-heart"][] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    measurementDate=$(echo $(_jq '.dateTime'))
    measurementFullDate="${measurementDate} 0000 UTC"
    measurementTS=$(date --date "${measurementDate}" +%s)
    measurementCorrectedTS=$((((measurementTS - $((userOffsetFromUTCMillis / 1000)))) * 1000000000))

    dateTodayShortDay=$(date --date "${measurementFullDate}" +%a)
    dateTodayLongDay=$(date --date "${measurementFullDate}" +%A)
    tags="${globalTags},shortDay=${dateTodayShortDay},longDay=${dateTodayLongDay},resolution=day"

    restingHeartrate=$(echo $(_jq '.value.restingHeartRate'))

    if [ "$restingHeartrate" -eq "$restingHeartrate" ] 2>/dev/null; then
        echo -e "heartrate,$tags restingHeartrate=$restingHeartrate $measurementCorrectedTS" >> fitbit.txt

        echo -e "heartrate,${tags} restingHeartrate=${restingHeartrate} $measurementCorrectedTS"
    fi

    for zone in $(echo $(_jq '.value') | jq -r '.heartRateZones[] | @base64'); do
        _zone() {
            echo ${zone} | base64 --decode | jq -r ${1}
        }

        caloriesOut=$(echo $(_zone '.caloriesOut'))
        max=$(echo $(_zone '.max'))
        min=$(echo $(_zone '.min'))
        minutes=$(echo $(_zone '.minutes'))
        name=$(echo $(_zone '.name') | tr -d '[:space:]')

        if [ "$caloriesOut" = "null" ]; then
            caloriesOut=0
        fi
        
        if [ "$minutes" = "null" ]; then
            minutes=0
        fi

        echo -e "heartrate,$tags,zone=$name caloriesOut=$caloriesOut $measurementCorrectedTS" >> fitbit.txt
        echo -e "heartrate,$tags,zone=$name max=$max $measurementCorrectedTS" >> fitbit.txt
        echo -e "heartrate,$tags,zone=$name min=$min $measurementCorrectedTS" >> fitbit.txt
        echo -e "heartrate,$tags,zone=$name minutes=$minutes $measurementCorrectedTS" >> fitbit.txt
        
        echo -e "heartrate,${tags},zone=${name} caloriesOut=${caloriesOut} $measurementCorrectedTS"
        echo -e "heartrate,${tags},zone=${name} max=${max} $measurementCorrectedTS"
        echo -e "heartrate,${tags},zone=${name} min=${min} $measurementCorrectedTS"
        echo -e "heartrate,${tags},zone=${name} minutes=${minutes} $measurementCorrectedTS"
    done
    
done