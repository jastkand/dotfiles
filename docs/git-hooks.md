# git hooks

# Prevent pushing to master

Add this pre-push hook to your repo

```bash
$ mv .git/hooks/pre-push.sample .git/hooks/pre-push
$ vi .git/hooks/pre-push
```

```bash
#!/bin/sh

while read local_ref local_sha remote_ref remote_sha
do
  if [ "$local_ref" = "refs/heads/master" ]
  then
    echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    echo " You cannot push to master! It's locked "
    echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    exit 1
  fi
done
exit 0
```
