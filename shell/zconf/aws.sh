which aws > /dev/null 

if [[ ! $? = 0 ]]
then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  sudo apt install unzip
  unzip awscliv2.zip
  sudo ./aws/install
fi

# AWS CLI Completion.
complete -C '/usr/local/bin/aws_completer' aws
