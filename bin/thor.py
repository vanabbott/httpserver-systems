#!/usr/bin/env python3

import concurrent.futures
import os
import requests
import sys
import time

# Functions

def usage(status=0):
    progname = os.path.basename(sys.argv[0])
    print(f'''Usage: {progname} [-h HAMMERS -t THROWS] URL
    -h  HAMMERS     Number of hammers to utilize (1)
    -t  THROWS      Number of throws per hammer  (1)
    -v              Display verbose output
    ''')
    sys.exit(status)

def hammer(url, throws, verbose, hid):
    ''' Hammer specified url by making multiple throws (ie. HTTP requests).

    - url:      URL to request
    - throws:   How many times to make the request
    - verbose:  Whether or not to display the text of the response
    - hid:      Unique hammer identifier

    Return the average elapsed time of all the throws.
    '''
    throw = 0
    avgTime = 0
    while throw < throws:
        start = time.time()
        response = requests.get(url)
        if response and verbose:
            print(f'{response.text}')
        elif not response:
            print('Request failed')

        singleTime = time.time() - start
        avgTime = avgTime + singleTime
        print(f'Hammer: {hid}, Throw:   {throw}, Elapsed Time: {round(singleTime, 2)}')

        throw = throw + 1

    avgTime = avgTime / throws

    print(f'Hammer: {hid}, AVERAGE   , Elapsed Time: {round(avgTime,2)}')


    return avgTime

def do_hammer(args):
    ''' Use args tuple to call `hammer` '''
    return hammer(*args)

def main():
    hammers = 1
    throws  = 1
    verbose = False
    flags = {'-v', '-t', '-h'}
    url = None

    # Parse command line arguments
    if len(sys.argv)>1:
        arguments = sys.argv[1:]
    else:
        usage(1)
    
    arg = 0
    while arg < len(arguments):
        if arguments[arg] in flags:
            if(arguments[arg] == '-v'):
                verbose = True
            elif(arguments[arg] == '-t'):
                throws = int(arguments[arg+1])
                arg+=1
            elif(arguments[arg] == '-h'):
                hammers = int(arguments[arg+1])
                arg+=1
        else:
            if(arguments[arg][0] == '-'):
                usage(1)
            else:
                url = arguments[arg]
        arg+=1

    if(hammers > 1):
        args = ((url, throws, verbose, hid) for hid in range(hammers)) 

        # Create pool of workers and perform throws
        with concurrent.futures.ProcessPoolExecutor(hammers) as executor:
            results = executor.map(do_hammer, args)

        avgTime = 0
        for result in results:
           avgTime = avgTime + result
        avgTime = avgTime / hammers
    else:
        avgTime = hammer(url, throws, verbose, 0)

    print(f'TOTAL AVERAGE ELAPSED TIME: {round(avgTime,2)}')
# Main execution

if __name__ == '__main__':
    main()

# vim: set sts=4 sw=4 ts=8 expandtab ft=python:
