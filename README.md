BruteZip
========

Tool for dictionary and brute force attacks against password protected compressed files.

Usage: brutezip [options]
    -f, --file FILE                  Zipped file protected with the password to guess (Mandatory)
    -d, --dictionary DICTIONARY      Dictionary file to use against the zipped file (Mandatory)
    -r, --resultdir [RESULTDIR]      Directory where the result of unzipping the file will be stored
    -t, --threads [NTHREADS]         Number of threads to bruteforce the password
    -h, --help                       Display this screen
