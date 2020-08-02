# Volvo Sensus Playlist Generator
Automatic playlist generator tool for generating valid playlists library for Volvo Sensus multimedia.


# Required perl modules
* File::Find
* File::Basename
* Music::Tag
* Music::Tag::FLAC
* Music::Tag::MP3
* Music::Tag::M4A
* Lingua::Translit

# Attention
Script **will rename non-english** filenames and foldres with media files (mp3, flac, mp4).

# Usage
```
./generate_m3u.pl PATH1 PATH2 PATH3
```

# Folder structure

The folder structure must be minimum 2 depth where 1 depth is genre or your classification. Folders depth in the "genre" category is unlimited.

**For example:**
```
Genre
  |
  --My Artist
    |
    -- Album1
  |
  -- Various
  |
  -- Альбом

Genre2
  |
  --Artist2
    |
    -- Year
      |
      -- Album2

```
Will generate 3 playslist with names:

* Genre - Album1
* Genre - Various
* Genre - Альбом
* Genre2 - Album2

And folder `Альбом` **will be renamed** to ``Al`bom``.