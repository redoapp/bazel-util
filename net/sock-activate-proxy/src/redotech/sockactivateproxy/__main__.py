__package__ = "redotech.sockactivateproxy"

from argparse import ArgumentParser
from asyncio import Future, gather, get_event_loop, open_connection, sleep, start_server
from contextlib import ExitStack
from socket import AF_INET, AF_INET6, SOCK_STREAM
from subprocess import Popen
from sys import exit, stderr, stdin
from redotech.net.addr import SockAddr, sock_addr_arg
from .asyncio import pipe

BUFFER_SIZE = 1024 * 4

parser = ArgumentParser(prog="sock-activate-proxy")
parser.add_argument("--listen", action="append", required=True, type=sock_addr_arg)
parser.add_argument("--forward", action="append", required=True, type=sock_addr_arg)
parser.add_argument("prog")
parser.add_argument("args", nargs="*")
args = parser.parse_args()

if len(args.listen) != len(args.forward):
    exit("Number of listen and forward addresses must match")


process = None


async def run_server(
    stack: ExitStack, forward: SockAddr, listen: SockAddr, prog: str, args: list[str]
):
    async def handle(reader, writer):
        global process
        if process is None:
            print("Starting", file=stderr)
            process = stack.enter_context(Popen([prog] + args))
        try:
            for i in range(20):
                try:
                    if forward.sock_type == SOCK_STREAM and forward.fam in (
                        AF_INET,
                        AF_INET6,
                    ):
                        remote_reader, remote_writer = await open_connection(
                            family=forward.fam,
                            host=forward.addr[0],
                            port=forward.addr[1],
                        )
                        break
                    else:
                        exit("Unsupported listen address")
                except Exception as e:
                    if i == 20 - 1:
                        exit("Could not connect")
                    await sleep(0.5)
            pipe1 = pipe(reader, remote_writer, BUFFER_SIZE)
            pipe2 = pipe(remote_reader, writer, BUFFER_SIZE)
            try:
                await gather(pipe1, pipe2)
            except Exception:
                pass
        finally:
            writer.close()

    if listen.fam in (AF_INET, AF_INET6) and listen.sock_type == SOCK_STREAM:
        host, port = listen.addr
    else:
        exit("Unsupported listen address")
    server = await start_server(handle, host=host, family=listen.fam, port=port)
    try:
        await Future()
    finally:
        server.close()


try:
    with ExitStack() as stack:
        loop = get_event_loop()
        try:
            loop.run_until_complete(
                gather(
                    *(
                        run_server(stack, forward, listen, args.prog, args.args)
                        for listen, forward in zip(args.listen, args.forward)
                    )
                )
            )
        finally:
            loop.run_until_complete(loop.shutdown_asyncgens())
            loop.close()
except KeyboardInterrupt:
    exit(1)
