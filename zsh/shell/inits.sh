# Tools initialization
eval "$(starship init zsh)"

eval "$(mise activate zsh)"

source <(fzf --zsh)

if command -v try &>/dev/null; then
  eval "$(try init ~/workspace/tries)"
fi
