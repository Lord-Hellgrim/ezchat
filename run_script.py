import subprocess


subprocess.run("ffmpeg -f dshow -framerate 30 -video_size 640x480 -i video=\"Integrated Camera\" -c:v libx264 -preset ultrafast -tune zerolatency -f mpegts pipe:1") 