#!/bin/sh

# echo "HTTP/1.0 200 OK"
# echo "Content-type: text/html"
# echo

CITY=$(echo $QUERY_STRING | sed -En 's|.*city=([^&]*).*|\1|p' | sed 's/&/ /g')
STATE=$(echo $QUERY_STRING | sed -En 's|.*state=([^&]*).*|\1|p' | sed 's/&/ /g')

if [ -z "$CITY" ] || [ -z "$STATE" ]; then
	CITY=Petersburg
	STATE=Alaska
fi

WEATHER=`./weather_2.sh -l "$CITY" "$STATE"`

echo "HTTP/1.0 200 OK"
echo "Content-type: text/html"
echo

cat <<EOF
<html>
<h1>Weather</h1>
<hr>
<form>
<input type="text" name="city" value="$CITY">
<input type="text" name="state" value="$STATE">
<input type="submit">
</form>
<h2> The weather in $CITY is $WEATHER </h2>
<hr>
</html>
EOF


# echo "<h2> $(./weather_2.sh -l "$CITY" "$STATE") </h2>"

