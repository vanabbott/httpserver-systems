#!/bin/sh

# Globals
CELSIUS=0
FORECAST=0
CITY="Petersburg"
STATE="Alaska"

# Functions

usage() {
		cat 1>&2 <<EOF
		Usage: weather_2.sh
		Returns weather forecast of given location
		-c 	flag to output weather in celsius
		-f	flag to output forecast with weather
		-l	flag to specify location should be followed with: "CITY" "STATE". Default is $CITY $STATE
		Returns weather of the lowest of the zipcodes in specified location.
EOF
		exit $1
}

getZip() {
		# Find zipcode of $CITY and $STATE 
		./zipcode.sh -c "$CITY" -s "$STATE" | head -n 1
}


# Parse command line arguments

while [ $# -gt 0 ]; do
		case $1 in
		-h) usage 0;;
		-c) CELSIUS=1;;
		-f) FORECAST=1;;
		-l) shift; CITY="$1"; shift; STATE="$1";;
		*) usage 1;;
		esac
		shift
done

# Get weather for zipcode found in getZip() finding celsius temp and/or forecast depending on flags

if [ $CELSIUS -eq 1 ]; then
		if [ $FORECAST -eq 1 ]; then
				./weather.sh -c -f `getZip` 
		else
				./weather.sh -c `getZip`
		fi
else 
		if [ $FORECAST -eq 1 ]; then
				./weather.sh -f `getZip`
		else
				./weather.sh `getZip`
		fi
fi 
