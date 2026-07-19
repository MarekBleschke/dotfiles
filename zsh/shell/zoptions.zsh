# Meta/UTF-8 settings
setopt COMBINING_CHARS

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=* l:|=*'

# Show all completions immediately without needing to press tab twice
setopt MENU_COMPLETE

# Mark symlinked directories (add trailing slash)
setopt CHASE_LINKS

# Colored completion listings
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Append to history file, don't overwrite
setopt APPEND_HISTORY

# Don't record duplicate commands
setopt HIST_IGNORE_ALL_DUPS

# Remove superfluous blanks before recording
setopt HIST_REDUCE_BLANKS

# Extended globbing
setopt EXTENDED_GLOB

# Don't beep on errors
unsetopt BEEP

