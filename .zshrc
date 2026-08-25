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

alias grlb='git branch --merged | grep -v "\*" | grep -v master | grep -v dev | xargs -n 1 git branch -d'
alias gfp='git fetch -p && git pull'
alias gss='git stash save'
alias gsp='git stash pop'
alias grm='git rebase $(git remote show origin | sed -n "/HEAD branch/s/.*: //p")'
alias gcem='gc --allow-empty -m "bump"'

# gwbd <branch>... -- delete branches, including ones checked out in a worktree.
# `git branch -D` refuses those and only tells you the path, so remove the worktree first
# and then delegate the deletion. A worktree with uncommitted or untracked files is left
# alone unless -f is given: losing that work is worse than a second run of the command.
# A locked worktree -- Claude Code locks the ones it opens for a session -- needs -ff, the
# same escalation `git worktree remove` itself asks for.
gwbd() {
  emulate -L zsh
  local -i n=0
  while [[ $1 == -* ]]; do
    case $1 in
      -f|--force) (( n++ )); shift ;;
      -ff) (( n += 2 )); shift ;;
      --) shift; break ;;
      *) print -u2 "gwbd: unknown option: $1"; return 1 ;;
    esac
  done
  (( $# )) || { print -u2 "usage: gwbd [-f|-ff] <branch>..."; return 1 }
  local -a force
  (( n > 0 )) && force=(--force)
  (( n > 1 )) && force+=(--force)
  git rev-parse --git-dir >/dev/null || return

  # Map branch -> worktree path. In the porcelain format every worktree is a record
  # starting with "worktree <path>", holding a "branch refs/heads/<name>" line unless it
  # is detached; the first record is always the main one, which cannot be removed.
  local -A worktrees
  # not `local path`: that shadows the special array zsh keeps tied to $PATH.
  local line wtpath main
  while IFS= read -r line; do
    case $line in
      worktree\ *) wtpath=${line#worktree }; : ${main:=$wtpath} ;;
      branch\ refs/heads/*) worktrees[${line#branch refs/heads/}]=$wtpath ;;
    esac
  done < <(git worktree list --porcelain)

  local branch dir here=${PWD:A}
  for branch in "$@"; do
    dir=${worktrees[$branch]}
    [[ -n $dir ]] || continue
    if [[ $dir == $main ]]; then
      print -u2 "gwbd: $branch is checked out in the main worktree, leaving $dir alone"
    elif [[ $here == ${dir:A} || $here == ${dir:A}/* ]]; then
      print -u2 "gwbd: you are inside $dir -- cd out of it first"
    elif [[ ! -d $dir ]]; then
      git worktree prune   # directory already gone by hand, just drop the registration
    elif ! git worktree remove $force "$dir"; then
      (( n == 0 )) && print -u2 "gwbd: rerun with -f to remove $dir anyway"
      (( n == 1 )) && print -u2 "gwbd: if $dir is locked, -ff overrides the lock"
    fi
  done

  git branch -D "$@"
}

alias lvh='rails s -p 3000 -b lvh.me'
alias rbe='PORT=3000 RAILS_MAX_THREADS=2 bundle exec puma -C config/puma.rb'
alias rdbm='bundle exec rake db:migrate'
alias rdbmt='bundle exec rake db:migrate RAILS_ENV=test'
alias rdbr='bundle exec rake db:rollback'
alias rdbrt='bundle exec rake db:rollback RAILS_ENV=test'

alias vlc='/Applications/VLC.app/Contents/MacOS/VLC'
alias vi="$(which vim)"

source $HOME/.profile

# --files: List files that would be searched but do not search
# --no-ignore: Do not respect .gitignore, etc...
# --hidden: Search hidden files and folders
# --follow: Follow symlinks
# --glob: Additional conditions for search (in this case ignore everything in the .git/ folder)
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'

PROMPT='%{$fg[yellow]%}[%D{%H:%M:%S}] '$PROMPT
