
# Dotfiles

My personal dotfiles.

### Filesystem layout

The repository mirrors global configuration paths under the home directory.
The installer symlinks selected, version-controlled `.config/*` paths into
`$XDG_CONFIG_HOME` (default `~/.config`). Machine-local settings stay outside
the repository under `$DOTFILES_LOCAL_HOME` (default
`$XDG_DATA_HOME/dotfiles`).

| Content | Location |
| --- | --- |
| Vim configuration | `$XDG_CONFIG_HOME/vim` |
| Vim undo history and views | `$XDG_DATA_HOME/vim` |
| Vim history, swap files, and backups | `$XDG_STATE_HOME/vim` |
| Neovim configuration/data/state/cache | Native `nvim` XDG directories |
| Global dotfiles shell defaults | `$XDG_CONFIG_HOME/dotfiles/profile.sh` |
| Machine-local dotfiles overrides | `$DOTFILES_LOCAL_HOME/profile.sh` |
| Machine-local environment values | `$DOTFILES_LOCAL_HOME/env` |
| Machine-local Liqid credentials | `$DOTFILES_LOCAL_HOME/liqid` |
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

The shell loads the version-controlled global profile first and the local
profile second. Put host-dependent values such as `DOTFILES_SOURCE_EXCLUDE`
only in the local profile. For example:

```sh
DOTFILES_SOURCE_EXCLUDE="bash_liqid zsh_liqid"
```

Copy `.env.example` to `$DOTFILES_LOCAL_HOME/env` for local credentials and
environment values. The installer migrates the legacy repository `.env`,
`~/.liqid` credentials, and local files written through an old whole-directory
`~/.config` symlink into their local destinations.


### Terminal

Both zsh and bash terminal profiles are available.  
The general settings should be set up as follows:  

![General Terminal Settings](/Assets/TerminalGeneralConfig.png "General Terminal Settings")
