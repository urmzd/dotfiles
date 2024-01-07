# Dotfiles

An automated set up for Debian-based operating systems.

```bash
	# Step 1. Install ansible.
	pip install ansible argcomplete
	# Step 2. Clean all files (if existing).
	rm -rf ~/.zshrc ~/.zshenv ~/.nvm ~/.gvm ~/.pyenv
	# Step 3. Execute the playbook.
	ansible-playbook ansible/playbook --ask-became-pass --user=urmzd
```
