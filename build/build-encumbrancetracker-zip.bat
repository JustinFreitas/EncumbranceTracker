:: Assumes running from EncumbranceTracker\build
mkdir out\EncumbranceTracker
copy ..\extension.xml out\EncumbranceTracker\
copy ..\readme.txt out\EncumbranceTracker\
copy ..\"Open Gaming License v1.0a.txt" out\EncumbranceTracker\
mkdir out\EncumbranceTracker\graphics\icons
copy ..\graphics\icons\encumbrance_icon.png out\EncumbranceTracker\graphics\icons\
mkdir out\EncumbranceTracker\scripts
copy ..\scripts\encumbrancetracker.lua out\EncumbranceTracker\scripts\
cd out
CALL ..\zip-items EncumbranceTracker
rmdir /S /Q EncumbranceTracker\
copy EncumbranceTracker.zip EncumbranceTracker.ext
cd ..
explorer .\out
