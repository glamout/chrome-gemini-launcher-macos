on run
	set cliPath to "__CLI_COMMAND__"
	try
		«event sysoexec» (quoted form of cliPath & " start")
	on error errorMessage number errorNumber
		«event sysodlog» errorMessage given «class btns»:{"OK"}, «class dflt»:"OK", «class wttl»:"Chrome Gemini Launcher"
	end try
end run
