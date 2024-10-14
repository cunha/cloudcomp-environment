#!/bin/bash
set -eu

while true ; do
    ps -u root -o pid | while read -r pid ; do
        if [[ $pid = PID ]] ; then continue ; fi
        if [[ ! -d /proc/$pid ]] ; then continue ; fi
        echo "root: echo -16 > /proc/$pid/oom_score_adj"
        echo "-16" > "/proc/$pid/oom_score_adj" || true
    done

    for user in hadoop cunha lucasmsp ; do
        ps -u $user -o pid | while read -r pid ; do
            if [[ $pid = PID ]] ; then continue ; fi
            if [[ ! -d /proc/$pid ]] ; then continue ; fi
            echo "$user: echo -15 > /proc/$pid/oom_score_adj"
            echo "-15" > "/proc/$pid/oom_score_adj" || true
        done
    done
    echo "$(date)"
    echo "sleeping 900s"
    sleep 900s
done
