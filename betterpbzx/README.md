#  betterpbzx

Extract new version pbzx files (split into payload.000, payload.001, ...) used in iOS OTA updates. Use http://newosxbook.com/articles/OTA3.html for the old version ("payload").

This is hacked together and should not be used to get an understanding of the file format or of the changes.

Partially broken: Using otaa on the result yields four corrupt entries and some funky stuff. Not sure if this is on my end or Levin's.

Result: Creates a .xz file for every input file or appends to the first xz if the -concat argument is passed.

License:

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
Version 2, December 2004

Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

Everyone is permitted to copy and distribute verbatim or modified
copies of this license document, and changing it is allowed as long
as the name is changed.

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. You just DO WHAT THE FUCK YOU WANT TO.
