import os
import subprocess

ip_list = {'TrueNas':'10.10.10.10', 'Desktop':'10.10.10.9', 'Torrent-box':'10.10.10.206'}
# , "10.10.10.43", "10.10.10.129", "10.10.10.15", "10.10.10.8", "10.10.10.11", "10.10.10.206"}
# ip_list = ["10.10.10.10"]

count = 2

# for ip in ip_list:
#     response = os.popen(f"ping -c {count} -W 3 {ip}").read()
#     if f"{count} received" in response:
#         print(f"{ip} is UP")
#     else:
#         print(f"{ip} is DOWN")

for key, value in ip_list.items():
    response = os.popen(f"ping -c {count} -W 3 {value}").read()
    if f"{count} received" in response:
        print(f"{key} is UP")
    else:
        print(f"{key} is DOWN")