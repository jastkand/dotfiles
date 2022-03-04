Trigger Configuration

```
use Chrome : application "Google Chrome"

property URL : "music.yandex.ru"
property _W : a reference to every window of Chrome
property _T : a reference to every tab of _W
property tab : a reference to (_T where its URL contains my URL)

if Chrome is not running then return "play"
if the number of _W = 0 or the number of my tab = 0 then return "play"

repeat with t in the contents of my tab
	execute of t javascript "var tr = JSON.parse(document.body.dataset.unityState || '{}'); if (tr.playing) { __glreturn__ = 'pause' } else { __glreturn__ = 'play' }"
end repeat
```

Action 1 Configuration

```
Copy of Trigger Configuration
```

Action 2 Configuration

```
use Chrome : application "Google Chrome"

property URL : "music.yandex.ru"
property _W : a reference to every window of Chrome
property _T : a reference to every tab of _W
property tab : a reference to (_T where its URL contains my URL)

if Chrome is not running then return
if the number of _W = 0 or the number of my tab = 0 then return

repeat with t in the contents of my tab
	execute of t javascript "var playBtn = document.querySelector('.player-controls__btn_play'); var pauseBtn = document.querySelector('.player-controls__btn_pause'); var tr = JSON.parse(document.body.dataset.unityState || '{}'); if (tr.playing) { pauseBtn && pauseBtn.click(); } else { playBtn && playBtn.click(); }"
end repeat
```
