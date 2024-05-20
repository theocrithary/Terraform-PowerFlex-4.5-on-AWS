#!/bin/bash
sudo I_AM_SURE=1 rpm -e `rpm -qa | grep -i EMC`
sudo rm -rf /tmp/scaleio-mdm/*
sudo rm -rf /opt/emc/scaleio/*
