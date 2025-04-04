zsh --version

# Force reload the zsh. Fixes the issue in Fork.app when pre-commit cannot be run
if [[ -z "$ZSH_VERSION" ]]; then
  exec zsh
fi

# Hide computer name
DEFAULT_USER=$USER
prompt_context(){}

# Path to your oh-my-zsh configuration.
export ZSH=$HOME/.oh-my-zsh

# For Solarized
export TERM="xterm-256color"

# Set name of the theme to load.
ZSH_THEME="agnoster"

# Comment this out to disable bi-weekly auto-update checks
DISABLE_AUTO_UPDATE="false"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
plugins=(gem git redis-cli ruby ssh-agent zsh-syntax-highlighting docker-compose asdf)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
export PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

alias lvh='rails s -p 3000 -b lvh.me'
alias grlb='git branch --merged | grep -v "\*" | grep -v master | grep -v dev | xargs -n 1 git branch -d'
alias gfp='git fetch -p && git pull'
alias gss='git stash save'
alias gsp='git stash pop'
alias grm='git rebase $(git remote show origin | sed -n "/HEAD branch/s/.*: //p")'
alias rbe='PORT=3000 RAILS_MAX_THREADS=2 bundle exec puma -C config/puma.rb'
alias rdbm='bundle exec rake db:migrate'
alias rdbmt='bundle exec rake db:migrate RAILS_ENV=test'
alias rdbr='bundle exec rake db:rollback'
alias rdbrt='bundle exec rake db:rollback RAILS_ENV=test'

alias vi="$(which vim)"

source $HOME/.profile

# --files: List files that would be searched but do not search
# --no-ignore: Do not respect .gitignore, etc...
# --hidden: Search hidden files and folders
# --follow: Follow symlinks
# --glob: Additional conditions for search (in this case ignore everything in the .git/ folder)
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'
