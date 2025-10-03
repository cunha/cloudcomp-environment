FROM python:3.13.7-slim-trixie

ENV ANSIBLE_PYTHON_INTERPRETER=/usr/local/bin/python3

RUN apt-get update &&\
    apt-get install -y --no-install-recommends curl=8.14.1-2 git=1:2.47.3-0+deb13u1 openssh-client=1:10.0p1-7 &&\
    pip install --no-cache-dir 'ansible==12.0.0' &&\
    pip cache purge &&\
    apt-get autoremove --purge -y &&\
    apt-get clean && rm -rf /var/lib/apt/lists/*