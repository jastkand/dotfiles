## ZSH

Install guide: https://github.com/robbyrussell/oh-my-zsh/blob/master/README.textile

List of themes: https://github.com/robbyrussell/oh-my-zsh/wiki/themes

Plugin for highlighting command: https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md#oh-my-zsh

## Agnoster theme

Powerline fonts repo: https://github.com/powerline/fonts

Monaco Powerline font: https://gist.github.com/baopham/1838072

Gruvbox: https://github.com/morhetz/gruvbox

# Aliases

```
# Runs rails with a bind to lvh.me
alias lvh='rails s -p 3000 -b lvh.me'

# Removes all local branches which had been already merged to master
alias grlb='git branch --merged | grep -v "\*" | grep -v master | grep -v dev | xargs -n 1 git branch -d'
```

## iTerm 2 Preferences

![](https://monosnap.com/file/TfT2Al997aNhU8YvCZMIjWoDq9CCgX.png)
