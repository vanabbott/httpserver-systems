#!/bin/sh

if [ "$#" -lt 1 ]; then
		echo "Usage: test_throughput.sh http://{HOST}:{PORT}"
		exit 1
fi

echo "AVERAGE THROUGHPUT TEST:					KB/SEC"
echo ""

PART=`./bin/thor.py $1/images/a.png -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
SIZE=`du -sk www/images/a.png | cut -f 1`
RESULT=`bc -l <<<"${SIZE}/${PART}"`
echo "Average Throughput for MEDIUM FILE /WWW/IMAGES/a.png:		`echo "scale=2; $RESULT / 1" | bc`"
echo "SIZE:	$SIZE kb"
echo "TIME:	$PART sec"

PART=`./bin/thor.py $1/images/b.png -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
SIZE=`du -sk www/images/b.jpg | cut -f 1`
RESULT=`bc -l <<<"${SIZE}/${PART}"`
echo "Average Throughput for MEDIUM FILE /WWW/IMAGES/b.jpg:		`echo "scale=2; $RESULT / 1" | bc`"
echo "SIZE:	$SIZE kb"
echo "TIME:	$PART sec"

PART=`./bin/thor.py $1/song.txt -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
SIZE=`du -sk www/song.txt | cut -f 1`
RESULT=`bc -l <<<"${SIZE}/${PART}"`
echo "Average Throughput for SMALL FILE /WWW/song.txt:		`echo "scale=2; $RESULT / 1" | bc`"
echo "SIZE:	$SIZE kb"
echo "TIME:	$PART sec"

PART=`./bin/thor.py $1/text/lyrics.txt -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
SIZE=`du -sk www/text/lyrics.txt | cut -f 1`
RESULT=`bc -l <<<"${SIZE}/${PART}"`
echo "Average Throughput for SMALL FILE /WWW/TEXT/lyrics.txt:		`echo "scale=2; $RESULT / 1" | bc`"
echo "SIZE:	$SIZE kb"
echo "TIME:	$PART sec"

exit 0
