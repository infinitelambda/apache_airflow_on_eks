import time
from resource import *

def sleep_ten_seconds():
    print("Sleeping for 10 seconds...")
    time.sleep(10)
    print("Done!")

    # Use script below to monitor mem usage
    # print(getrusage(RUSAGE_SELF))
    # if you want rss only # .getrusage(resource.RUSAGE_SELF).ru_maxrss
    # print(getrusage(RUSAGE_SELF).ru_maxrss)

if __name__ == "__main__":
    sleep_ten_seconds()
