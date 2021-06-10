#!/bin/bash
echo "First arg: $1"
miq_hostname=$1
hostnamectl set-hostname  $miq_hostname