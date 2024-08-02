tell application "Finder"
	if (exists window 1) then
		set myWin to window 1
		set thePath to (POSIX path of (target of myWin as alias))
		
		tell application "Terminal"
			if (exists window 1) and not busy of window 1 then
				activate
				do script "cd " & thePath in window 1
			else
				activate
				do script "cd " & thePath
			end if
		end tell
	else
		tell application "Terminal"
			activate
			do script ""
		end tell
	end if
end tell