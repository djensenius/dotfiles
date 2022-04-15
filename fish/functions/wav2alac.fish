function wav2alac
  for f in *.wav
    ffmpeg -i "$f" -map 0:0 -c:a:0 alac (basename $f .wav).m4a
  end
end
