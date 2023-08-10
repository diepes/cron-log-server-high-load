#!/usr/bin/env bash
docker run -it -v $(pwd):/src -w /src --rm --name test-cron-log-in-container debian:stable
apt update ; apt upgrade ; apt install procps bc ;

