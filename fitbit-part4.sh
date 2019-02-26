# Steps
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

    echo -e "activity,${tags} steps=${steps} $measurementCorrectedTS\n"
done