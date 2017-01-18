
set PERSONAL_ACCESS_TOKEN=<INSERT_YOUR_TOKEN_HERE>

cmd /c tfx extension publish --manifest-globs vss-extension.json --token %PERSONAL_ACCESS_TOKEN%

pause
