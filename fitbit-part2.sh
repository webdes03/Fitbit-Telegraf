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