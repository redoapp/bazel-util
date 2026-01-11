__package__ = "redotech.ibazelsockactivate"

from argparse import ArgumentParser
from os import dup2, getpid, environ, execvp
from selectors import DefaultSelector, EVENT_READ
from socket import socket, SO_REUSEADDR, SOL_SOCKET
from sys import stderr, stdin
from redotech.net.addr import sock_addr_arg

try:
    parser = ArgumentParser(prog="sock-activate")
    parser.add_argument("--addr", action="append", default=[], type=sock_addr_arg)
    parser.add_argument("prog")
    parser.add_argument("args", nargs="*")
    args = parser.parse_args()

    selector = DefaultSelector()

    socks = []
    for addr in args.addr:
        sock = socket(addr.fam, addr.sock_type)
        sock.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
        sock.bind(addr.addr)
        sock.listen(5)
        sock.setblocking(False)
        socks.append(sock)
        selector.register(sock, EVENT_READ)

    selector.register(stdin, EVENT_READ)

    while True:
        for key, _ in selector.select():
            if key.fileobj == stdin:
                line = stdin.buffer.readline()
            else:
                break
        else:
            continue
        break

    print("Starting", file=stderr)
    environ["LISTEN_FDS"] = str(len(socks))
    environ["LISTEN_PID"] = str(getpid())
    for fd, sock in enumerate(socks, 3):
        dup2(sock.fileno(), fd)
except KeyboardInterrupt:
    pass

execvp(args.prog, [args.prog] + args.args)
