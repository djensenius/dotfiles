Clickety Split Ltd. | Pepito-Macro

build with default keymap:
    west build -d build/pepito/left -p -b seeeduino_xiao_ble -- -DSHIELD=clickety_split_pepito_left
    west build -d build/pepito/right -p -b seeeduino_xiao_ble -- -DSHIELD=clickety_split_pepito_right

build with custom keymap:
    west build -d build/pepito/left -p -b seeeduino_xiao_ble -- -DSHIELD=clickety_split_pepito_left  -DZMK_CONFIG="/workspaces/zmk-config/joey/pepito_v1.13/config"
    west build -d build/pepito/right -p -b seeeduino_xiao_ble -- -DSHIELD=clickety_split_pepito_right  -DZMK_CONFIG="/workspaces/zmk-config/joey/pepito_v1.13/config"
