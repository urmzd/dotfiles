# Workaround: GitHub Copilot CLI has shell issues with non-standard paths/shells.
# Prepend system paths and set SHELL to system bash before launching.
copilot() {
  PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH" \
  SHELL=/bin/bash \
    command copilot "$@"
}
