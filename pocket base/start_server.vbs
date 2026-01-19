Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "cmd.exe /c pocketbase.exe serve --http=""0.0.0.0:8090""", 0, False

