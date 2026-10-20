
TODO

## Моя временная куча:

```sh
export VOXELCORE_DIR=$HOME/dev/voxelcore-0.32.2
export VOXELCORE_DIR=$HOME/dev/voxelcore-game-jam-26 # чёт не пашет, пишет что нет project.toml, хотя я ничего не менял в scr

export VOXELCORE=$VOXELCORE_DIR/result/bin/VoxelEngine

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

TODO

