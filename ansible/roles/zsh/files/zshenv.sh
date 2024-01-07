
# Begin added by argcomplete
fpath=( /home/urmzd/.local/lib/python3.10/site-packages/argcomplete/bash_completion.d "${fpath[@]}" )
# End added by argcomplete

# Extend PATH
# replace /home/urmzd with /home/{{ ansible_user }}
export PATH="/home/urmzd/.local/bin:$PATH"
