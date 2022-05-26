# Assets

## Bubble

The bubble asset was created using the following (clunky) procedure:

1. I created the bubble sprites in PyxelEdit (`bubble.pyxel`)
2. I exported `bubble.pyxel` as a tileset to `bubble.png` (File > Export > Tileset)
3. I converted `bubble.png` to an indexed-color png using AseSprite (Sprite > Color Mode > Indexed) and saved
4. I imported `bubble.png` into bmp2tile and exported the palette and pattern data

- The tiles had `Remove duplicates` and `Planar tile output` selected. Planar is required for SMS patterns. Note that `Use tile mirroring` can't be used for sprites on the SMS but should be used for background tiles

### bmp2tile

- Program: https://github.com/maxim-zhao/bmp2tile/releases
- Compression codecs: https://github.com/maxim-zhao/bmp2tilecompressors/releases

Place compressor .dlls into the same directory as bmp2Tile. For this example I just used the `raw` compressor which allows us to export the data as an uncompressed binary file.

## font.bin

The font file was taken from Maxim's Hello World SMS programming tutorial: https://www.smspower.org/maxim/HowToProgram/Lesson1AllOnOnePage

## tilemap

Rough workflow:

1. Created new Aseprite document with indexed colour mode and imported the Master System palette
2. Drew tilemap using the tilesheet features in v1.3
3. Selected unused palette entries and deleted them
4. Exported png using File > Export
5. Imported into bmp2tile and exported the bin files (palette, patterns, tilemap)