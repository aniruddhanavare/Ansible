#!/bin/bash
echo "First arg: $1"
miq_hostname=$1
mkdir /tmp/test123
hostnamectl set-hostname  $miq_hostname