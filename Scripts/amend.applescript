
tell application "Terminal"
	activate
end tell

delay 0.5
-- get enire contents
tell application "System Events"
	tell process "Terminal"
		delay 0.1
		keystroke "ga ."
		key code 76
		delay 0.1
		keystroke "gcma"
		key code 76
		delay 0.1
		keystroke ":wq"
		key code 76
		delay 0.2
		keystroke "gps"
		key code 76
	end tell
end tell