# git hooks

# Prevent pushing to master

Add this update hook to your repo

```bash
$ mv .git/hooks/update.sample .git/hooks/update
$ vi .git/hooks/update
```

```bash
#!/bin/sh
# lock the master branch for pushing
refname="$1"

if [[ $refname == "refs/heads/master" ]]
then
    echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    echo " You cannot push to master! It's locked "
    echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    exit 1
fi
exit 0
```
