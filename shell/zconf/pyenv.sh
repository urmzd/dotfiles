where pyenv >> /dev/null

if [[ "$?" -ne 0 ]]
then
  curl https://pyenv.run | zsh
  sudo apt-get update; sudo apt-get install make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
fi

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
