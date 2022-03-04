# Now Playing

## Trigger configuration

Source Type: Apple Script

```applescript
tell application "System Events"
	set num to count (every process whose name is "Music")
end tell

set maxSize to 40

if num > 0 then
	tell application "Music"
		set playState to (player state as text)
		if playState is equal to "playing" then
			set trackName to name of current track
			set artistName to artist of current track
			set trackInfo to artistName & " - " & trackName

			if length of trackInfo is greater than maxSize then
				set trackInfo to text 1 thru (maxSize - 3) of trackInfo & "..."
			end if
		else
			if player state is paused then
				set trackInfo to "Paused"
			else
				set trackInfo to "Tap to start music"
			end if
		end if
		return trackInfo
	end tell
else
	set trackInfo to "Music not running"
	return trackInfo
end if
```

## Actions Assigned

Source Type: Run Apple Script

```applescript
if application "Music" is running then
	tell application "Music"
		if player state is playing then
			next track
		end if

		if player state is paused then
			playpause
		end if

		if player state is stopped then
			set shuffle enabled to true
			play playlist "Library"
		end if
	end tell
end if
```
