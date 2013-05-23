#!/bin/sh

for file in *.png
do
    mv $file $file~
    convert $file~  +dither -monochrome -trim trim.tmp.png
    pngcrush -m 107 -m 119 trim.tmp.png $file
done
rm trim.tmp.png
