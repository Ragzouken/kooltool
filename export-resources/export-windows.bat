:: export-windows.bat project_name saves_directory
rmdir /s/q %2\releases\%1\
mkdir %2\releases\%1\

:: copy binaries
copy /y %2\releases\7za.exe %2\releases\%1\7za.exe
xcopy /y/s/e/v/q %2\releases\kooltool-player-love %2\releases\%1\kooltool-player-love\
xcopy /y/s/e/v/q %2\releases\love-binary-win %2\releases\%1\love-binary-win\
xcopy /y/s/e/v/q %2\releases\love-binary-osx %2\releases\%1\love-binary-osx\

:: build player from blank player and project, archive
xcopy /y/s/e/v/q %2\projects\%1 %2\releases\%1\kooltool-player-love\embedded\
%2\releases\%1\7za.exe -tzip a %2\releases\%1\%1-love.zip %2\releases\%1\kooltool-player-love\*
rmdir /s/q %2\releases\%1\kooltool-player-love

:: .love (linux)
copy /y %2\releases\%1\%1-love.zip %2\releases\%1\%1.love

:: .zip (windows)
copy /b %2\releases\%1\love-binary-win\love.exe+%2\releases\%1\%1-love.zip %2\releases\%1\love-binary-win\%1.exe
del %2\releases\%1\love-binary-win\love.exe
rename %2\releases\%1\love-binary-win\ %1
%2\releases\%1\7za.exe -tzip a %2\releases\%1\%1.zip %2\releases\%1\%1\
rmdir /s/q %2\releases\%1\%1\

:: .app.zip (osx)
copy /y %2\releases\%1\%1.love %2\releases\%1\love-binary-osx\Contents\Resources\%1.love
rename %2\releases\%1\love-binary-osx\ %1.app
%2\releases\7za.exe -tzip a %2\releases\%1\%1.app.zip %2\releases\%1\%1.app\
rmdir /s/q %2\releases\%1\%1.app\

:: clean up
::rmdir /s/q %2\releases\%1\kooltool-player-love\
del %2\releases\%1\7za.exe
del %2\releases\%1\%1-love.zip
del %2\releases\export-windows.bat
