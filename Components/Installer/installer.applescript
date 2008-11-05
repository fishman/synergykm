-- Install Synergy.applescript
-- Install Synergy

--  Created by Lorenz Schori on 30.07.05.
--  Copyright 2005 __MyCompanyName__. All rights reserved.

--
-- this script installs and removes synergy prefpane and help into the system
-- or the users Library. attention is taken for removing synergy beta1 to not
-- accidentially remove synergy, the itunes controller
--
-- todo:
-- ¥ there are way too much hardcoded paths!!!
-- ¥ better communication / user interface
-- ¥ localisation
--

-- 
-- HANDLER
--
--
-- button event handler
--
on clicked theObject
	if name of theObject is "chooseActionButtons" then
		if current row of theObject < 3 then
			set (title of button "actionButton" of (window of theObject)) to "Install"
		else
			set (title of button "actionButton" of (window of theObject)) to "Uninstall"
		end if
	else if name of theObject is "actionButton" then
		set theaction to current row of matrix "chooseActionButtons" of window of theObject
		if theaction < 3 then
			-- INSTALL SYNERGY
			-- quit System Preferences if its running
			tell application "System Events"
				set spproc to every process where name is "System Preferences"
			end tell
			if length of spproc > 0 then
				quit application "System Preferences"
			end if
			
			-- remove old synergy if installed
			set installType to isSynergyInstalled()
			set isrunning to isSynergydRunning()
			
			if installType > 0 then
				if (synergyUninstall() is true) then
					set upgrading to true
				else
					display dialog "Could not uninstall previous version of Synergy. Please try again"
				end if
			end if
			
			-- install Synergy.prefPane + Help
			set r to false
			if theaction is 1 then
				set r to synergyInstall("User")
			else if theaction is 2 then
				set r to synergyInstall("System")
			end if
			if r is false then
				display dialog "Could not complete installation of Synergy. Please try again"
				return
			end if
			
			-- display dialog and finish
			if r is 1 then
				-- install ok
				set msg to "Installation of Synergy was successfull"
			else
				-- upgrade ok
				set msg to "Upgrade of Synergy was successfull"
			end if
			set r to display dialog msg buttons {"OK", "Configure"} default button "Configure"
			if button returned of r is "Configure" then
				run script "
					on run x
						tell application \"System Preferences\"
							activate
							set current pane to pane \"net.sourceforge.synergy2.synergypane\"
						end tell
					end run"
			end if
			
		else
			-- REMOVE SYNERGY
			-- quit System Preferences if its running
			tell application "System Events"
				set spproc to every process where name is "System Preferences"
			end tell
			if length of spproc > 0 then
				quit application "System Preferences"
			end if
			
			-- actually remove the stuff
			if synergyUninstall() is true then
				display dialog "Synergy was successfully removed from your computer" buttons {"OK"} default button "OK"
			else
				display dialog "Synergy was not found on your computer. Nothing removed" buttons {"OK"} default button "OK"
				return
			end if
		end if
	end if
end clicked

-- 
-- INFORMATION
--
--
-- test if Synergyd is running
--
on isSynergydRunning()
	tell application "System Events"
		set sdproc to every process where name is "Synergyd"
	end tell
	return (length of sdproc > 0)
end isSynergydRunning


--
-- synergyBeta1InstalledInSystemDomain()
--
on isSynergyBeta1InstalledInSystemDomain()
	set r to false
	try
		do shell script "test -e /Library/PreferencePanes/Synergy.prefPane/Contents/Resources/Synergyd.app"
		set r to true
	end try
	return r
end isSynergyBeta1InstalledInSystemDomain

--
-- synergyBeta1InstalledInUserDomain()
--
on isSynergyBeta1InstalledInUserDomain()
	set r to false
	try
		do shell script "test -e ~/Library/PreferencePanes/Synergy.prefPane/Contents/Resources/Synergyd.app"
		set r to true
	end try
	return r
end isSynergyBeta1InstalledInUserDomain

--
-- synergyKMInstalledInSystemDomain()
--
on isSynergyKMInstalledInSystemDomain()
	set r to false
	try
		do shell script "test -e /Library/PreferencePanes/SynergyKM.prefPane -o -e \"/Library/Documentation/Help/SynergyKM Help\""
		set r to true
	end try
	return r
end isSynergyKMInstalledInSystemDomain

--
-- synergyKMInstalledInUserDomain()
--
on isSynergyKMInstalledInUserDomain()
	set r to false
	try
		do shell script "test -e ~/Library/PreferencePanes/SynergyKM.prefPane -o -e \"~/Library/Documentation/Help/SynergyKM Help\""
		set r to true
	end try
	return r
end isSynergyKMInstalledInUserDomain

--
-- isSynergyInstalled()
--
on isSynergyInstalled()
	set r to 0
	if isSynergyBeta1InstalledInSystemDomain() or isSynergyKMInstalledInSystemDomain() then
		set r to 2
	else if isSynergyBeta1InstalledInUserDomain() or isSynergyKMInstalledInUserDomain() then
		set r to 1
	end if
	return r
end isSynergyInstalled

-- 
-- INSTALLATION
--
--
-- synergyInstalled()
--
on synergyInstall(inDomain)
	-- test and remember if synergy was running
	tell application "System Events"
		set folderpath to POSIX path of container of (path to me)
	end tell
	set helpBookPath to quoted form of (folderpath & "/SynergyKM Help")
	set prefpanePath to quoted form of (folderpath & "/SynergyKM.prefPane")
	
	set r to false
	if inDomain is "User" then
		-- try
		do shell script "mkdir -p ~/Library/Documentation/Help && cp -pr " & helpBookPath & " ~/Library/Documentation/Help"
		do shell script "mkdir -p ~/Library/PreferencePanes && cp -pr " & prefpanePath & " ~/Library/PreferencePanes"
		set r to true
		-- end try
	else if inDomain is "System" then
		try
			do shell script "mkdir -p /Library/Documentation/Help && cp -pr " & helpBookPath & " /Library/Documentation/Help" with administrator privileges
			do shell script "mkdir -p /Library/PreferencePanes && cp -pr " & prefpanePath & " /Library/PreferencePanes" with administrator privileges
			set r to true
		end try
	end if
	return r
end synergyInstall

-- 
-- DEINSTALLATION
-- 
--
-- remove Synergy.prefPane (Beta 1) without touching Synergy (the iTunes controller)
--
on synergyUninstall()
	-- test and remember if synergy was running
	set isrunning to isSynergydRunning()
	
	-- try to quit synergyd
	if isrunning is true then
		tell main bundle
			set quitutilloc to path to me
		end tell
		set quitutilpath to quoted form of ((POSIX path of quitutilloc) & "Contents/Resources/quitsynergyd")
		
		repeat with i from 0 to 4
			if isrunning is true then
				try
					do shell script quitutilpath
				end try
				delay 1
				set isrunning to isSynergydRunning()
			end if
		end repeat
		
		if isrunning is true then
			-- tell user that synergyd could not quit
			display dialog "ERROR: could not quit synergy. please do it yourself"
			return false
		end if
	end if
	
	set synergyRemoved to false
	
	-- remove Synergy.prefPane (Beta 1) in system domain without harming Synergy iTunes controller
	try
		do shell script "test -e /Library/PreferencePanes/Synergy.prefPane/Contents/Resources/Synergyd.app"
		do shell script "rm -rf /Library/PreferencePanes/Synergy.prefPane" with administrator privileges
		set synergyRemoved to true
	end try
	-- remove Synergy.prefPane (Beta 1) in user domain without harming Synergy iTunes controller
	try
		do shell script "test -e ~/Library/PreferencePanes/Synergy.prefPane/Contents/Resources/Synergyd.app"
		do shell script "rm -rf ~/Library/PreferencePanes/Synergy.prefPane"
		set synergyRemoved to true
	end try
	
	-- remove SynergyKM.prefPane & Help folder (> Beta 1) in system domain
	set prefpanePath to "/Library/PreferencePanes/SynergyKM.prefPane"
	set helpBookPath to "/Library/Documentation/Help/SynergyKM Help"
	try
		-- test first if some of the components are installed, don't ask for admin password if not nessesary.
		do shell script "test -e " & quoted form of prefpanePath & " -o -e " & quoted form of helpBookPath
		do shell script "rm  -rf " & quoted form of prefpanePath & " " & quoted form of helpBookPath with administrator privileges
		set synergyRemoved to true
	end try
	
	-- remove SynergyKM.prefPane & Help folder (> Beta 1) in user domain
	set pfx to POSIX path of (path to home folder)
	set prefpanePath to pfx & prefpanePath
	set helpBookPath to pfx & helpBookPath
	try
		do shell script "test -e " & quoted form of prefpanePath & " -o -e " & quoted form of helpBookPath
		do shell script "rm  -rf " & quoted form of prefpanePath & " " & quoted form of helpBookPath
		set synergyRemoved to true
	end try
	
	-- restart SystemUIServer if apporpriate 
	try
		do shell script "defaults read com.apple.systemuiserver | grep -e \"SynergyKM\\.menu\" && killall SystemUIServer"
	end try
	return synergyRemoved
end synergyUninstall
