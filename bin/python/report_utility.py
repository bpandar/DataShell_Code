#!/usr/bin/python

import pandas as pd

"""
This python module contains functions used in report generation
"""


def add_leading_char(x, char, char_len, lib='pd'):
    """Adds a number of leading character/s to a given string

    x : str
        The original string that the leading characters are added
    char : str
        The leading character we are adding to the string
    char_len : integer
        The max length of the string.
        abs. value of (char_len) - (length of string x) gives us the amount of leading characters to add
    res : str
        The modified string with the added leading characters
    lib : pandas or polars (default is pandas)

    Example:
        x = 444
        char = 0
        char_len = 5
        res = 00444
    """
    num = abs(char_len - len(str(x)))
    res = (char * num) + str(x)
    if pd.isna(x):
        res = x

    return res

