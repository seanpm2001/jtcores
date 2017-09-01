#!/bin/bash

OD="od -t x1 -A none -v -w1"
ODx2="od -t x2 -A none -v -w2"

function curpos() {
	printf "%X" $(cat gng.hex | wc -l)
}

## Game ROM
$ODx2 mmt03d.8n --endian little > gng.hex 
echo "10N starts at " $(curpos)
$ODx2 mmt04d.10n --endian little >> gng.hex 
echo "13N starts at " $( curpos )
$ODx2 mmt05d.13n --endian little >> gng.hex 
echo "Characters start at " $(curpos)
$ODx2 mm01.11e >> gng.hex 
echo "Scroll tiles start at " $(curpos)
$OD mm09.3c > 3c.hex
$OD mm07.3b > 3b.hex
paste 3c.hex 3b.hex -d "" | tr -d ' ' > 3bc.hex
$OD mm11.3e > 3e.hex
paste 3bc.hex 3e.hex -d "\n" >> gng.hex

$OD mm08.1c > 1c.hex
$OD mm06.1b > 1b.hex
paste 1c.hex 1b.hex -d "" | tr -d ' ' > 1bc.hex
$OD mm10.1e > 1e.hex
paste 1bc.hex 1e.hex -d "\n" >> gng.hex

echo "Scroll tiles end at " $(curpos)

## Object ROM, 16kBx4 = 64kB
$ODx2 
../cc/bytemerge mm{16.3n,13.3l} 3nl
../cc/bytemerge mm{15.1n,12.1l} 1nl
echo "// Object ROM " >> gng.hex
echo "@50000" >> gng.hex
$ODx2 3nl >> gng.hex 
$ODx2 1nl >> gng.hex 

## Sound ROM, 32kB
##echo "// Sound ROM " >> gng.hex
##echo "@30000" >> gng.hex
##$ODx2 mm02.14h >> gng.hex 
../cc/hex2bin