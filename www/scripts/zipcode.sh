#!/bin/sh
#Globals

URL=https://www.zipcodestogo.com/
STATE=Indiana
c=0


# Functions

usage() {
		cat 1>&2 <<EOF
				Usage: zipcode.sh

				-c      CITY    Which city to search
				-s      STATE   Which state to search (Indiana)

				If no CITY is specified, then all the zip codes for the STATE are displayed.
EOF
		exit $1
}

zipcodes() {
		STATE=$(echo $STATE | sed 's/ /%20/')
		if [ $c -eq 1 ]; then
				curl -s $URL$STATE/ | grep "/$CITY/" | cut -d '/' -f 6 | sed -n '/[0-9]/p' 
		else
				curl -s $URL$STATE/ | grep -E '//www\.z' | cut -d '/' -f 6 | sed -n '/[0-9]/p'
		fi
}


# Parse Command Line Options

while [ $# -gt 0 ]; do
		case $1 in
				-h) usage 0;;
				-c) shift; CITY="$1"; c=1;;
				-s) shift; STATE="$1";;
				*) usage 1;;
		esac
		shift
done

# Filter Pipeline(s)


for zip in $(zipcodes); do
		echo $zip
done


