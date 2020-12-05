#!/bin/sh

if [ "$#" -lt 1 ]; then
		echo "Usage: test_latency.sh http://{HOST}:{PORT}"
		exit 1
fi

echo "AVERAGE LATENCY TEST:						TIME(SEC)"
echo ""

PART=`./bin/thor.py $1 -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
echo "Average Latency for DIRECTORY LISTING /WWW:			$PART" 

PART=`./bin/thor.py $1/html -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
echo "Average Latency for DIRECTORY LISTING /WWW/HTML:		$PART" 

PART=`./bin/thor.py $1/images -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
echo "Average Latency for DIRECTORY LISTING /WWW/IMAGES:		$PART" 

PART=`./bin/thor.py $1/scripts -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
echo "Average Latency for DIRECTORY LISTING /WWW/SCRIPTS:		$PART" 

echo ""

PART=`./bin/thor.py $1/html/index.html -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
echo "Average Latency for STATIC FILES /WWW/HTML/index.html:		$PART" 

PART=`./bin/thor.py $1/images/a.png -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
echo "Average Latency for STATIC FILES /WWW/IMAGES/a.png:		$PART" 

PART=`./bin/thor.py $1/images/b.png -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
echo "Average Latency for STATIC FILES /WWW/IMAGES/b.png:		$PART" 

PART=`./bin/thor.py $1/song.txt -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
echo "Average Latency for STATIC FILES /WWW/song.txt:			$PART" 

echo""


PART=`./bin/thor.py $1/scripts/hello.py -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
echo "Average Latency for CGI SCRIPTS /WWW/SCRIPTS/hello.py:		$PART" 

PART=`./bin/thor.py $1/scripts/cowsay.sh -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
echo "Average Latency for CGI SCRIPTS /WWW/SCRIPTS/cowsay.sh:		$PART" 

PART=`./bin/thor.py $1/scripts/env.sh -t 5 -h 5 | grep "TIME" | sed -En "s/^.*([0-9]+\.[0-9]+)$/\1/p"`
echo "Average Latency for CGI SCRIPTS /WWW/SCRIPTS/env.sh:		$PART" 

exit 0
