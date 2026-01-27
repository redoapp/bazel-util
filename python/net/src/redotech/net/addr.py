from argparse import ArgumentTypeError
from collections import namedtuple
from dataclasses import dataclass
from socket import (
    AF_INET,
    AF_INET,
    AF_INET6,
    AF_UNIX,
    SOCK_DGRAM,
    SOCK_STREAM,
    SocketKind,
)
from typing import Any


@dataclass
class SockAddr:
    addr: Any
    fam: str
    sock_type: SocketKind


def sock_addr_arg(str):
    protocol, addr = str.split(":", 1)
    protocol = protocol.lower()
    if protocol == "udp":
        if addr.startswith("["):
            host, port = addr[1:].split("]:", 1)
        else:
            host, port = addr.split(":", 1)
        return SockAddr(addr=(host, int(port)), fam=AF_INET6, sock_type=SOCK_DGRAM)
    if protocol == "unix-dgram":
        return SockAddr(addr=addr, fam=AF_UNIX, sock_type=SOCK_DGRAM)
    if protocol == "unix-stream":
        return SockAddr(addr=addr, fam=AF_UNIX, sock_type=SOCK_STREAM)
    if protocol == "tcp":
        host, port = addr.split(":", 1)
        if addr.startswith("["):
            host, port = addr[1:].split("]:", 1)
        else:
            host, port = addr.split(":", 1)
        return SockAddr(addr=(host, int(port)), fam=AF_INET6, sock_type=SOCK_STREAM)
    raise ArgumentTypeError(f"Unknown protocol: {protocol}")
