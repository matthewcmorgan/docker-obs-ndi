#!/bin/bash

OUR_IP=$(hostname -i)
openssl req -new -x509 -days 365 -nodes -out self.pem -keyout self.pem
rm -rf /tmp/.X*

# start VNC server (Uses VNC_PASSWD Docker ENV variable)
mkdir -p /tmp/.vnc && echo "$VNC_PASSWD" | vncpasswd -f > /tmp/.vnc/passwd

# start noVNC web server
/opt/noVNC/utils/launch.sh --listen 5901 &
vncserver :0 -localhost no -nolisten -rfbauth /tmp/.vnc/passwd -xstartup /opt/x11vnc_entrypoint.sh

echo -e "\n\n------------------ VNC environment started ------------------"
echo -e "\nVNCSERVER started on DISPLAY= $DISPLAY \n\t=> connect via VNC viewer with $OUR_IP:5900"
echo -e "\nnoVNC HTML client started:\n\t=> connect via http://$OUR_IP:5901/?password=$VNC_PASSWD\n"

if [ -z "$1" ]; then
  tail -f /dev/null
else
  # unknown option ==> call command
  echo -e "\n\n------------------ EXECUTE COMMAND ------------------"
  echo "Executing command: '$*'"
  exec "$@"
fi
