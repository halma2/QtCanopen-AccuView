#!/bin/bash

# This shell script is only for Raspberry PI (model 4b) with touchpad

# Arguments (optional):
# --venv: the path of the virtual python interpreter, default: ./myvenv
# --program_dir: the file path of the main python script, default: ./main.py
# --requirements: the file path of the listed required packages of main.py that pip should install,
#                 default: ./requirements.txt
# --rotation: the rotation of the touch pad (normal, left, right, inverted), default: right
# --log: the file path of the log file where any messages and errors will be written by main.py,
#        default: ./out.log

set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Default values
# Raspberry PI Touch Display 2 - 7" Portrait
DISPLAY_NAME=DSI-1

# Rotation setting (normal, left, right, inverted)
ROTATION=right

VENV=myenv
QT_PROGRAM=main.py
LOG_FILE=out.log
REQUIREMENTS_LIST=requirements.txt


#-----------------------------
# Parsing CL arguments
#-----------------------------

while [ $# -gt 0 ]; do
    case "$1" in
        --venv)
            VENV="$2"
            shift 2
            ;;
       --program_dir)
            QT_PROGRAM="$2"
            shift 2
            ;;
       --requirements)
            REQUIREMENTS_LIST="$2"
            shift 2
            ;;
       --rotation)
            ROTATION="$2"
            shift 2
            ;;
       --touchpad)
            DISPLAY_NAME="$2"
            shift 2
            ;;
       --log)
            LOG_FILE="$2"
            shift 2
            ;;
       *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done


echo "Updating and installing system packages..."

apt update
apt upgrade -y


apt install -y --no-install-recommends \
    xserver-xorg \
    xinit \
    openbox \
    x11-xserver-utils \
    mesa-utils
apt install -y \
    libgl1 \
    libegl1 \
    libopengl0 \
    libfontconfig1 \
    libxkbcommon0 \
    lightdm \
    python3-xdg \
    python-pip \
    fonts-noto-color-emoji

echo "Enable graphical boot..."

systemctl enable lightdm
systemctl set-default graphical.target

echo "Configure LightDM..."

# LightDM config already exists; we only modify [Seat:*] section safely
LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
if grep -q "^\[Seat:\*\]" "$LIGHTDM_CONF"; then
    # Comment out existing xserver-command if present
    sed -i 's/^\s*xserver-command/#xserver-command/g' "$LIGHTDM_CONF"
    # Ensure required settings exist under [Seat:*]
    if ! grep -q "autologin-user=$USER" "$LIGHTDM_CONF"; then
        sed -i "/^\[Seat:\*\]/a autologin-user=$USER_NAME" "$LIGHTDM_CONF"
    fi
    if ! grep -q "autologin-user-timeout=0" "$LIGHTDM_CONF"; then
        sed -i "/^\[Seat:\*\]/a autologin-user-timeout=0" "$LIGHTDM_CONF"
    fi
    if ! grep -q "user-session=openbox" "$LIGHTDM_CONF"; then
        sed -i "/^\[Seat:\*\]/a user-session=openbox" "$LIGHTDM_CONF"
    fi
    # Add explicit xserver-command override with -nocursor
    if ! grep -q "xserver-command=X -nocursor" "$LIGHTDM_CONF"; then
        sed -i "/^\[Seat:\*\]/a xserver-command=X -nocursor" "$LIGHTDM_CONF"
    fi
fi

echo "Configure openbox..."

mkdir -p ~/.config/openbox

cat > ~/.config/openbox/autostart <<EOF
#!/bin/bash

# Apply screen rotation based on ROTATION variable
case "$ROTATION" in
    normal)
        XRANDR_ROT="normal"
        MATRIX="1 0 0 0 1 0 0 0 1"
        ;;
    left)
        XRANDR_ROT="left"
        MATRIX="0 -1 1 1 0 0 0 0 1"
        ;;
    right)
        XRANDR_ROT="right"
        MATRIX="0 1 0 -1 0 1 0 0 1"
        ;;
    inverted)
        XRANDR_ROT="inverted"
        MATRIX="-1 0 1 0 -1 1 0 0 1"
        ;;
    *)
        XRANDR_ROT="normal"
        MATRIX="1 0 0 0 1 0 0 0 1"
        ;;
esac

xrandr --output "$DISPLAY_NAME" --rotate "$XRANDR_ROT"

# Rotating the tochscreen coordination system
TOUCH=\$(xinput list | grep -i touchscreen | sed -E 's/.*id=([0-9]+).*/\1/')

if [ -n "\$TOUCH" ]; then
    xinput set-prop \$TOUCH \ "Coordinate Transformation Matrix" \"$MATRIX"
fi

source "$VENV"
python "$QT_PROGRAM" >> "$LOG_FILE" 2>&1
EOF


chmod +x ~/.config/openbox/autostart


echo "Configure Python venv..."

python -m venv "$VENV"

source "$VENV/bin/activate"

pip install --upgrade pip

if [ -f "$REQUIREMENTS_LIST" ]; then
    pip install -r "$REQUIREMENTS_LIST"
else
    echo "Requirements list is not found!"
fi

deactivate

echo "Enviroment variable DISPLAY=:0 is set in /etc/enviroment"
echo DISPLAY:=0 >> /etc/enviroment

echo "Installation and configurations are done!"
echo "Reboot starts after 5 seconds"
sleep 5
reboot
