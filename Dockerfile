FROM ubuntu:21.04
ARG DEBIAN_FRONTEND="noninteractive"

RUN apt-get update \ 
	&& apt-get install -y gnupg 

# Add OBS PPA Repo
RUN echo "deb http://ppa.launchpad.net/obsproject/obs-studio/ubuntu hirsute main" >> /etc/apt/sources.list
RUN echo "deb-src http://ppa.launchpad.net/obsproject/obs-studio/ubuntu hirsute main" >> /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BC7345F522079769F5BBE987EFC71127F425E228

# Run APT for All the things
RUN apt-get update \ 
	&& apt-get install -y avahi-daemon fluxbox git obs-studio tigervnc-standalone-server vlc wget xterm \
	&& apt-get upgrade -y \
	&& apt-get clean -y \
	&& rm -rf /var/lib/apt/lists/* 

RUN mkdir -p /config/obs-studio /root/.config/
RUN ln -s /config/obs-studio/ /root/.config/obs-studio 
RUN sed -i 's/geteuid/getppid/' /usr/bin/vlc 

# Setup NoVNC Repos
RUN git clone --branch v1.2.0 --single-branch https://github.com/novnc/noVNC.git /opt/noVNC
RUN git clone --branch v0.10.0 --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify
RUN ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Grab and install NDI Binaries
RUN wget -q -O /tmp/libndi4_4.5.1-1_amd64.deb https://github.com/Palakis/obs-ndi/releases/download/4.9.1/libndi4_4.5.1-1_amd64.deb
RUN wget -q -O /tmp/obs-ndi_4.9.1-1_amd64.deb https://github.com/Palakis/obs-ndi/releases/download/4.9.1/obs-ndi_4.9.1-1_amd64.deb 
RUN dpkg -i /tmp/*.deb \ 
	&& rm -rf /tmp/*.deb 

# Add Local Run Scripts
RUN mkdir -p /opt/startup_scripts

COPY startup.sh /opt/startup_scripts/
COPY container_startup.sh /opt/
COPY x11vnc_entrypoint.sh /opt/

RUN chmod +x /opt/*.sh 
RUN chmod +x /opt/startup_scripts/*.sh

# Add menu entries to the container
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"OBS Screencast\" command=\"obs\"" >> /usr/share/menu/custom-docker
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"Xterm\" command=\"xterm -ls -bg black -fg white\"" >> /usr/share/menu/custom-docker && update-menus

# Use environment variable to allow custom VNC passwords
ENV VNC_PASSWD=123456

VOLUME ["/config"]
EXPOSE 5900 5901
ENTRYPOINT ["/opt/container_startup.sh"]
