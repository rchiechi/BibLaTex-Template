#!/bin/bash

perl -pi.bak -e 's+\\red\{(.*?)\}+$1+g' "$1"
