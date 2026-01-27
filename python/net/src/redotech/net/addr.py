from argparse import ArgumentTypeError
from dataclasses import dataclass
from socket import (
    AF_INET,
    AF_INET6,
    AF_UNIX,
    SOCK_DGRAM,
    SOCK_STREAM,
    AddressFamily,
    SocketKind,
)
from typing import Any


@dataclass
class SockAddr:
    addr: Any
    fam: AddressFamily
    sock_type: SocketKind


def _parse_inet_addr(addr: str) -> tuple[str, int]:
    if addr.startswith("["):
        host, port = addr[1:].split("]:", 1)
    else:
        host, port = addr.rsplit(":", 1)
    return host, int(port)


def sock_addr_arg(str):
    protocol, addr = str.split(":", 1)
    protocol = protocol.lower()
    if protocol == "tcp4":
        host, port = _parse_inet_addr(addr)
        return SockAddr(addr=(host, port), fam=AF_INET, sock_type=SOCK_STREAM)
    if protocol == "tcp6":
        host, port = _parse_inet_addr(addr)
        return SockAddr(addr=(host, port), fam=AF_INET6, sock_type=SOCK_STREAM)
    if protocol == "tcp":
        host, port = _parse_inet_addr(addr)
        return SockAddr(addr=(host, port), fam=AF_INET6, sock_type=SOCK_STREAM)
    if protocol == "udp4":
        host, port = _parse_inet_addr(addr)
        return SockAddr(addr=(host, port), fam=AF_INET, sock_type=SOCK_DGRAM)
    if protocol == "udp6":
        host, port = _parse_inet_addr(addr)
        return SockAddr(addr=(host, port), fam=AF_INET6, sock_type=SOCK_DGRAM)
    if protocol == "udp":
        host, port = _parse_inet_addr(addr)
        return SockAddr(addr=(host, port), fam=AF_INET6, sock_type=SOCK_DGRAM)
    if protocol == "unix-dgram":
        return SockAddr(addr=addr, fam=AF_UNIX, sock_type=SOCK_DGRAM)
    if protocol == "unix-stream":
        return SockAddr(addr=addr, fam=AF_UNIX, sock_type=SOCK_STREAM)

    raise ArgumentTypeError(f"Unknown protocol: {protocol}")
