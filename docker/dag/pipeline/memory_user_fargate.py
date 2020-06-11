from resource import *
import time
import sys

def use_memory():
    l = []
    for i in range(0, 2):
        l.append("***" * 1024 * 3100 * 400)

    # Use script below to monitor mem usage
    print(getrusage(RUSAGE_SELF))
    # if you want rss only # .getrusage(resource.RUSAGE_SELF).ru_maxrss
    byt = getrusage(RUSAGE_SELF).ru_maxrss
    print(byt / (2 ** 30), "GB")

if __name__ == "__main__":
    print("Executing function in 5 seconds...")
    time.sleep(5)
    use_memory()
    time.sleep(5)
    print("Script run complete!")


