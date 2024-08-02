tell application "Terminal"
	activate
end tell

delay 0.5
-- get enire contents
tell application "System Events"
	tell process "Terminal"
		-- Open Preferences
		keystroke "," using command down
		key code 48
		delay 1
		click button "Profiles" of toolbar 1 of window 1
		tell window "Profiles"
			click menu button 1 of group 1
			click menu item "Import…" of menu 1 of menu button 1 of group 1
			delay 1
			keystroke "f" using command down
			keystroke "Bash.terminal"
			delay 0.5
			click menu item "Name Contains “Bash.terminal”" of menu 1 of UI element 3 of text field 1 of sheet 1
			key code 48
			key code 48
			delay 0.5
			key code 124
			key code 76
			delay 1
			click menu button 1 of group 1
			click menu item "Import…" of menu 1 of menu button 1 of group 1
			delay 1
			keystroke "f" using command down
			keystroke "Zsh.terminal"
			delay 0.5
			click menu item "Name Contains “Zsh.terminal”" of menu 1 of UI element 3 of text field 1 of sheet 1
			key code 48
			key code 48
			delay 0.5
			key code 124
			key code 76
			delay 0.5
			key code 48
			repeat 15 times
				key code 125
			end repeat
			click button "Default" of group 1
		end tell
		click button "General" of toolbar 1 of window 1
		tell window "General"
			click pop up button 1 of group 1
			click menu item "Zsh" of menu 1 of pop up button 1 of group 1
			click radio button "Command (complete path):" of radio group "Shells open with:" of group 1
			delay 0.5
			set value of text field 1 of group 1 to "/bin/bash"
		end tell
		keystroke "w" using command down
		delay 0.2
	end tell
end tell