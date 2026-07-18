# Dotfiles

My personal dotfiles inspired by [Holmans doftiles](https://github.com/holman/dotfiles) and [Omarchy](https://github.com/basecamp/omarchy).


## Stack

- uses [mise](https://mise.jdx.dev/) for workstation bootstrapping and dotfiles management (see [mise.toml](https://github.com/MarekBleschke/dotfiles/blob/new-mise/mise.toml) for config)
- currently using `zsh` + `oh-my-zsh` + `starship` for shell
- use `~/.localrc` if you want something to be sourced but not committed to the repository (e.g., secrets, tokens, private environment variables)
- [bootstrap]() is bootstrapping script which runs basic installs and invokes `mise bootstrap`

## How to use

> [!NOTE]
> [mise.toml](https://github.com/MarekBleschke/dotfiles/blob/new-mise/mise.toml) is configured to use `~/workspace/dotfiles/` as directory for this repo. If you want to change this edit [those lines](https://github.com/MarekBleschke/dotfiles/blob/new-mise/mise.toml#L32-L33) in `mise.toml` before running `./bootrstrap`.

```sh
git clone git@github.com:MarekBleschke/dotfiles.git 
cd dotfiles
./bootstrap
```
