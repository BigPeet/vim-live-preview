#!/usr/bin/env python3

import argparse
import os

# Source dev_run_loop.vim
# Invoke the command VLPPython with optional arguments, for example:
# :VLPPython -q -n John
# :VLPPython --quiet
# :VLPPython

# def oops(): # this is invalid syntax and will lead to an error

def main():
    # get $USER
    parser = argparse.ArgumentParser()
    parser.add_argument("-n", "--name", help="name of the person", default=os.getenv("USER"))
    parser.add_argument("-q", "--quiet", help="decrease output verbosity", action="store_true")
    args = parser.parse_args()
    if args.quiet:
        print("Hello, {}!".format(args.name))
    else:
        print("Hello, {}.".format(args.name.upper()))

if __name__ == "__main__":
    main()
