import psutil
import json
import datetime
from icecream import ic
import redis
import time

TCP_IP = '127.0.0.1'
TCP_PORT = 6379

publisher = redis.Redis(host = TCP_IP, port = TCP_PORT, db=0)

INTERVAL_TIME = 5

def time_format():
    return f'{datetime.datetime.now()}|> '

ic.configureOutput(prefix=time_format, includeContext=True)

def convert_complex2dict(tmp, fields, ap=False):
    tmp_dict = {}
    if ap:
        fields = ["{}-{}".format(fields, i) for i in range(len(tmp))]
    else:
        fields = ["{}-{}".format(fields, f) for f in tmp._fields]
    for i, name in enumerate(fields):
        tmp_dict[name] = tmp[i]
    return tmp_dict


iteration = 0
while True:
    result = {"timestamp": str(datetime.datetime.now())}
    result.update(convert_complex2dict(psutil.cpu_percent(percpu=True), "cpu_percent", ap=True))
    result['cpu_freq_current'] = psutil.cpu_freq()[0]
    result.update(convert_complex2dict(psutil.cpu_stats(), "cpu_stats", ap=False))
    result.update(convert_complex2dict(psutil.virtual_memory(), "virtual_memory", ap=False))
    result['n_pids'] = len(psutil.pids())
    tmp = psutil.net_io_counters(pernic=True).get("eth0") #eth0
    result.update(convert_complex2dict(tmp, "net_io_counters_eth0", ap=False))

    # after stream-node-max-bytes (4kb) or stream-node-max-entries (100),
    # this topic will be trimmed to 5 entries

    #publisher.xadd(name="metrics", fields={"msg": json.dumps(result)},  maxlen=5)
    publisher.set("metrics", json.dumps(result))
    iteration += 1
    if iteration % 100000 == 0:
        ic(result)
    time.sleep(INTERVAL_TIME)