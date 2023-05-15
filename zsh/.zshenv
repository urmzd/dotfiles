if [[ -z "PATH" || "$PATH" == "/bin:/usr/bin" ]]
then
	export PATH="/usr/local/bin:$PATH"
	export PATH="/usr/bin:$PATH"
	export PATH="/usr/games:$PATH"
fi

export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:/usr/local/bin/fdfind"
export PATH="$PATH:/usr/local/bin/go/bin"
export PATH="$PATH:/usr/local/lib/luarocks/rocks-5.1/luaformatter/scm-1/bin"
export PATH="$PATH:$HOME/.rbenv/bin"
export PATH="$PATH:$HOME/.rbenv/shims/"
export PATH="$PATH:$HOME/.julia/julia"
export PATH="$PATH:/opt/gradle/gradle-8.0-20220913040000+0000/bin"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export KUBECONFIG=~/.kube/config.yaml
