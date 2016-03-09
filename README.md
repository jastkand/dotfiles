ZSH
---

Install guide: https://github.com/robbyrussell/oh-my-zsh/blob/master/README.textile

List of themes: https://github.com/robbyrussell/oh-my-zsh/wiki/themes

Plugin for highlighting command: https://github.com/zsh-users/zsh-syntax-highlighting

---

Agnoster theme
--------------

Patched fonts for agnoster theme: https://gist.github.com/qrush/1595572

Agnoster theme patch: https://gist.github.com/cscheid/6194756

    $ cd ~/.oh-my-zsh/themes
    $ patch -p2 < unbreak_powerline.patch
    
    diff --git a/themes/agnoster.zsh-theme b/themes/agnoster.zsh-theme
    index e652938..a9de8c8 100644
    --- a/themes/agnoster.zsh-theme
    +++ b/themes/agnoster.zsh-theme
    @@ -26,7 +26,7 @@
     # A few utility functions to make it easy and re-usable to draw segmented prompts
    
     CURRENT_BG='NONE'
    -SEGMENT_SEPARATOR=''
    +SEGMENT_SEPARATOR='⮀'

Powerline fonts repo: https://github.com/Lokaltog/powerline-fonts

---

Solarized theme: https://github.com/altercation/solarized

    if has('gui_running')
      set guifont=Monaco:h12    " set fonts for gui vim
      set transparency=5        " set transparent window
      set guioptions=egmrt  " hide the gui menubar
    endif


# Aliases

```
# Runs rails with a bind to lvh.me
alias lvh='rails s -p 3000 -b lvh.me'

# Removes all local branches which had been already merged to master
alias grlb='git branch --merged | grep -v "\*" | grep -v master | grep -v dev | xargs -n 1 git branch -d'
```
