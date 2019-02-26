# Get profile from Fitbit
getProfile=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accesstoken}" -H "Accept-Language: ${units}" "https://api.fitbit.com/1/user/-/profile.json")

# Get UTC offset for user
userOffsetFromUTCMillis=$(echo "$getProfile" | jq ".user.offsetFromUTCMillis")

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