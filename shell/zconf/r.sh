sudo apt update -qq -y
sudo apt install --no-install-recommends -y software-properties-common dirmngr
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a -y /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
sudo apt install --no-install-recommends -y r-base
sudo add-apt-repository ppa:c2d4u.team/c2d4u4.0+ -y
