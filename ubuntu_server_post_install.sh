#!/usr/bin/env bash

set -euo pipefail

echo "Ubuntu update script"

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y
sudo apt-get autoclean -y
