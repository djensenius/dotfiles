function flac2alac
  for f in *.flac
    ffmpeg -i "$f" -map 0:0 -c:a:0 alac (basename $f .flac).m4a
  end
end
