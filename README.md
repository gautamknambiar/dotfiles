
# Dotfiles

My personal dotfiles.

### Filesystem layout

The repository mirrors configuration paths under the home directory. The
installer symlinks `.config/*` into `$XDG_CONFIG_HOME` (default `~/.config`)
and keeps generated files out of the repository.

| Content | Location |
| --- | --- |
| Vim configuration | `$XDG_CONFIG_HOME/vim` |
| Vim undo history and views | `$XDG_DATA_HOME/vim` |
| Vim history, swap files, and backups | `$XDG_STATE_HOME/vim` |
| Neovim configuration/data/state/cache | Native `nvim` XDG directories |
| Dotfiles shell state | `$XDG_STATE_HOME/dotfiles` |
| Bitbucket download cache | `$XDG_CACHE_HOME/bbdl` |
| Vim build source | `$XDG_CACHE_HOME/dotfiles/vim/source` |
| Installer backups | `$XDG_DATA_HOME/dotfiles/backups` |
| Versioned Vim installation | `~/.local/opt/vim-9.2` |

Unset XDG variables use their standard defaults: `~/.config`,
`~/.local/share`, `~/.local/state`, and `~/.cache`.
Tool-native exceptions remain in place where overriding them would be less
predictable; for example, Bash continues to use `~/.bash_history` and NVM
continues to use `~/.nvm`.


### Terminal

Both zsh and bash terminal profiles are available.  
The general settings should be set up as follows:  

![General Terminal Settings](/Assets/TerminalGeneralConfig.png "General Terminal Settings")
