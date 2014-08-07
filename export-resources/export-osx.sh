#!/bin/sh 
releases="$( cd "$( dirname "$0" )" && pwd )"

# export-osx.sh project_name saves_directory
rm -rf "$releases/$1"
mkdir "$releases/$1"

# copy binaries
cp -rf "$releases/kooltool-player-love" "$releases/$1/kooltool-player-love"
cp -rf "$releases/love-binary-win" "$releases/$1/love-binary-win"
cp -rf "$releases/love-binary-osx" "$releases/$1/love-binary-osx"

# build player from blank player and project, archive
cp -rf "$releases/../projects/$1" "$releases/$1/kooltool-player-love/embedded"
cd "$releases/$1/kooltool-player-love"
zip -r "../$1-love.zip" *
cd "$releases"
rm -rf "$releases/$1/kooltool-player-love"

# .love (linux)
cp "$releases/$1/$1-love.zip" "$releases/$1/$1.love"

# .zip (windows)
cat "$releases/$1/love-binary-win/love.exe" "$releases/$1/$1-love.zip" > "$releases/$1/love-binary-win/$1.exe"
rm "$releases/$1/love-binary-win/love.exe"
mv "$releases/$1/love-binary-win/" "$releases/$1/$1"
cd "$releases/$1"
zip -r "$releases/$1/$1.zip" "$1"
cd ..
rm -rf "$releases/$1/$1/"

# .app.zip (osx)
cp -f "$releases/$1/$1.love" "$releases/$1/love-binary-osx/Contents/Resources/$1.love"
mv "$releases/$1/love-binary-osx" "$releases/$1/$1.app"
chmod +x "$release/$1/$1.app/Contents/Resources/MacOS/love"
cd "$releases/$1"
zip -r "$releases/$1/$1.app.zip" "$1.app"
cd ..
rm -rf "$releases/$1/$1.app"

# clean up
rm "$releases/$1/$1-love.zip"
rm "$releases/export-osx.sh"
rm -rf "$releases/kooltool-player-love"
rm -rf "$releases/love-binary-win"
rm -rf "$releases/love-binary-osx"
