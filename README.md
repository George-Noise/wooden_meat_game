
TODO

## Моя временная куча:

### VoxelCore

```sh
export VOXELCORE_DIR=$HOME/dev/voxelcore-0.32.2
export VOXELCORE=$VOXELCORE_DIR/result/bin/VoxelEngine

export VOXELCORE_DIR=$HOME/dev/voxelcore-game-jam-26
export VOXELCORE=$VOXELCORE_DIR/result/bin/VoxelCore # переименовано в VoxelCore

# run
WAYLAND_DISPLAY= XDG_SESSION_TYPE=x11 \
  $VOXELCORE \
  --dir $VOXELCORE_DIR \
  --res $VOXELCORE_DIR/res

# run Project
WAYLAND_DISPLAY= XDG_SESSION_TYPE=x11 \
  $VOXELCORE \
  --dir $VOXELCORE_DIR \
  --res $VOXELCORE_DIR/res \
  --project $HOME/dev/wooden_meat_game/

```

### SFX

stream vorbis mono
```sh
ffmpeg -i some.ogg -af "pan=mono|c0=c0" -c:a libvorbis -q:a 5 some_vorbis_mono.ogg
```

cave
```sh
ffmpeg -i brown_noise.ogg -af "pan=mono|c0=c0,highpass=f=25,lowpass=f=250:poles=2,lowpass=f=250:poles=2" -c:a libvorbis -q:a 5 cave_drone.ogg
```

TODO

