#!/sbin/python

import sys
import time
import os


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


allbars = "[//////////]"
emptybars = "[          ]"

home = os.getenv("HOME")

with open(home + "/.volume") as f:
    content = f.readlines()

with open(home + "/.mute") as f:
    isunmuted = (int(f.readlines()[0]) == 0)

if isunmuted:
    volume = int(content[0])
    bars = int(volume / 9000)

    if (volume % 9000 == 0):
        output = allbars[0:bars+1] + emptybars[bars+1:]
    if (volume % 9000 == 3000):
        output = allbars[0:bars+1] + "." + emptybars[bars+2:]
    if (volume % 9000 == 6000):
        output = allbars[0:bars+1] + "-" + emptybars[bars+2:]
else:
    output = "[  (mute)  ]"


print(output)
sys.stdout.flush
