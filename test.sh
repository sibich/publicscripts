#!/bin/bash

user=$(whoami)
echo "Hello $user from ARM" > /home/vitaly/test_`date +%d-%m-%Y"_"%H_%M_%S`.txt

