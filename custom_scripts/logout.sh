#!/usr/bin/env bash

kill $(who -u | awk 'NR==1{print $6}')
