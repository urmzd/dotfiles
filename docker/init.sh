#!/usr/bin/bash

# Check if docker is running.
if [[ -f /var/run/docker.pid ]] 
then
  # Stop docker.
  sudo service docker stop 
fi

# Start docker.
sudo service docker start 
