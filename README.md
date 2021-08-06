# CC-Images

```bash
wget run https://raw.githubusercontent.com/Commandcracker/CC-Images/master/lua/download.lua
```

## Third Party Libraries

| Library                                 | Maintainer                                              |
|-----------------------------------------|---------------------------------------------------------|
| [GIF](https://pastebin.com/5uk9uRjC)    | [BombBloke](https://pastebin.com/u/BombBloke)           |
| [BBPack](https://pastebin.com/cUYTGbpb) | [BombBloke](https://pastebin.com/u/BombBloke)           |
| [Json](https://pastebin.com/4nRg9CHU)   | [ElvishJerricco](https://pastebin.com/u/ElvishJerricco) |

## create nfp

### download videos

with [youtube-dl](https://github.com/ytdl-org/youtube-dl#installation) or with a gui [youtube_downloader](https://gitlab.com/Commandcracker/youtube_downloader)

```bash
youtube-dl <url>
```

### split videos in images

with [ffmpeg](https://ffmpeg.org/download.html)

```bash
ffmpeg -i <video_file> -vf fps=1/2 part_%04d.png
```

### rezize and convert image to .nfp

with [convert_nfp.py](https://github.com/DownrightImpractical/computercraft-stuff)

```bash
python3 convert_nfp.py <images> --resize-width <width> --resize-height <height> --remove
```
