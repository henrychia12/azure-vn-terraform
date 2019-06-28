#!/bin/bash

# updating the system
sudo apt-get update
sudo apt-get upgrade -y

# installing unzip and wget tools
sudo apt-get install -y unzip wget

# downloading latest terraform to date (28/06/19) -  terraform 0.12.3
wget https://releases.hashicorp.com/terraform/0.12.3/terraform_0.12.3_linux_386.zip

# extract the terraform zip archive
unzip terraform_*_linux_*.zip

# deleting old or existing terraform
sudo rm -f /usr/local/bin/terraform

# moving terraform binary to /usr/local/bin folder
sudo mv terraform /usr/local/bin

# remove download zip file
sudo rm terraform_*_linux_*.zip

# check to see if terraform successfully installed
terraform --version
