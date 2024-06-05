#!/usr/bin/env python3

import argparse
import os

# Source dev_run_loop.vim
# Invoke the command VLPPython with optional arguments, for example:
# :VLPPython -v John
# :VLPPython --verbose
# :VLPPython

def main():
    # get $USER
    parser = argparse.ArgumentParser()
    parser.add_argument("-n", "--name", help="name of the person", default=os.getenv("USER"))
    parser.add_argument("-v", "--verbose", help="increase output verbosity", action="store_true")
    args = parser.parse_args()
    if args.verbose:
        print("Hello, {}!".format(args.name.upper()))
    else:
        print("Hello, {}.".format(args.name))

if __name__ == "__main__":
    main()
