# Now Playing

## Trigger configuration

Source Type: Apple Script

```applescript
if application "Google Chrome" is running then
	tell application "Google Chrome"
		repeat with t in tabs of windows
			tell t
				if URL starts with "https://music.yandex.ru" then
					set query to "tr = externalAPI.getCurrentTrack(); document.body.dataset.bttMusicTitle = JSON.stringify({ text: tr.artists.map(a => a.title).join(', ') + ' - ' + tr.title, icon_path: tr.cover.replace('%%', '50x50') })" as text
					tell t to set URL to "javascript:" & query
					set musicTitle to execute of t javascript "__glreturn__ = document.body.dataset.bttMusicTitle"
					return musicTitle
				end if
			end tell
		end repeat
	end tell
else
	return "Music not running"
end if



use Chrome : application "Google Chrome"

property URL : "music.yandex.ru"
property _W : a reference to every window of Chrome
property _T : a reference to every tab of _W
property tab : a reference to (_T where its URL contains my URL)

if Chrome is not running then return "Music not running"
if the number of _W = 0 or the number of my tab = 0 then return "Music not running"

repeat with t in the contents of my tab
	set musicTitle to execute of t javascript "var tr = JSON.parse(document.body.dataset.unityState || '{}'); if (tr.playing) { __glreturn__ = tr.artist + ' - ' + tr.title } else { __glreturn__ = 'Tap to start music' }"
	return musicTitle
end repeat
```

## Actions Assigned

Source Type: Run Apple Script

```applescript
use Chrome : application "Google Chrome"

property URL : "music.yandex.ru"
property _W : a reference to every window of Chrome
property _T : a reference to every tab of _W
property tab : a reference to (_T where its URL contains my URL)

if Chrome is not running then return
if the number of _W = 0 or the number of my tab = 0 then return

repeat with t in the contents of my tab
	execute of t javascript "var playBtn = document.querySelector('.player-controls__btn_play'); var nextBtn = document.querySelector('.player-controls__btn_next'); var tr = JSON.parse(document.body.dataset.unityState || '{}'); if (tr.playing) { nextBtn && nextBtn.click(); } else { playBtn && playBtn.click(); }"
end repeat
```
