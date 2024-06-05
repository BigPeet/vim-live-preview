#!/usr/bin/env python3

import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("name", help="name of the person")
    parser.add_argument("-v", "--verbose", help="increase output verbosity", action="store_true")
    args = parser.parse_args()
    if args.verbose:
        print("Hello, {}!".format(args.name.upper()))
    else:
        print("Hello, {}.".format(args.name))

if __name__ == "__main__":
    main()
