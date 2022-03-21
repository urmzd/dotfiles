where terraform >> /dev/null 

if [[ ! $? = 0 ]]
then
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
  sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

  # Install terraform.
  sudo apt install terraform
fi

# Terraform Completion. 
complete -o nospace -C /usr/bin/terraform terraform
