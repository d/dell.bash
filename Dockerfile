FROM ubuntu:rolling
RUN apt-get update -q && apt-get install -y squid-deb-proxy-client
CMD service avahi-daemon start && /etc/init.d/squid-deb-proxy start
