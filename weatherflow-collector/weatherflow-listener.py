#!/usr/bin/python
# -*- coding: utf-8 -*-

# Reference - Python Listener - https://github.com/p-doyle/Simple-WeatherFlow-Python-Listener

import socket
import select
import time
import struct
import pprint
import json
import datetime


# create broadcast listener socket

def create_broadcast_listener_socket(broadcast_ip, broadcast_port):

    b_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM,
                           socket.IPPROTO_UDP)
    b_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    b_sock.bind(('', broadcast_port))

    mreq = struct.pack('4sl', socket.inet_aton(broadcast_ip),
                       socket.INADDR_ANY)
    b_sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)

    return b_sock


# ip/port to listen to

BROADCAST_IP = '239.255.255.250'
BROADCAST_PORT = 50222

# create the listener socket

sock_list = [create_broadcast_listener_socket(BROADCAST_IP,
             BROADCAST_PORT)]

while True:

    # small sleep otherwise this will loop too fast between messages and eat a lot of CPU

    time.sleep(0.01)

    # wait until there is a message to read

    (readable, writable, exceptional) = select.select(sock_list, [],
            sock_list, 0)

    # for each socket with a message

    for s in readable:
        (data, addr) = s.recvfrom(4096)

        data = data.decode('utf-8')
        print (data)
