set WINRAR="C:\Program Files\WinRar\Winrar.exe"

if exist procexp.zip del procexp.zip
if exist procexp-source.zip del procexp-source.zip

rem Archive binary
%WINRAR% a procexp.zip ..\ProcessExplorer.exe ..\file_id.diz ..\README ..\HISTORY
if errorlevel == 1 goto err

rem Archive source
%WINRAR% a procexp-source.zip ..\*.pas ..\*.dpr ..\*.dfm ..\*.dof ..\*.cfg ..\*.res ..\ImageList.bmp ..\README ..\HISTORY
if errorlevel == 1 goto err
goto finish

:err
pause
:finish
