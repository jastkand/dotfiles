Trigger Configuration

```
tell application "System Events"
	set num to count (every process whose name is "Music")
end tell

if num > 0 then
	tell application "Music"
		if player state is playing then
			return "pause"
		else
			return "play"
		end if
	end tell
else
	return "play"
end if
```

Action 1 Configuration

```
Copy of Trigger Configuration
```

Action 2 Configuration

```
if application "Music" is running then
	tell application "Music" to playpause
else
	do shell script "open -a Music"
end if
```
