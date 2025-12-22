import dataclasses
import enum


@dataclasses.dataclass
class BuildStarted:
    pass


class BuildStatus(enum.Enum):
    FAILURE = "FAILURE"
    SUCCESS = "SUCCESS"


@dataclasses.dataclass
class BuildCompleted:
    status: BuildStatus


def read(input):
    for line in input:
        message = line.strip()
        if message == "IBAZEL_BUILD_STARTED":
            yield BuildStarted()
        elif message == "IBAZEL_BUILD_COMPLETED FAILURE":
            yield BuildCompleted(BuildStatus.FAILURE)
        elif message == "IBAZEL_BUILD_COMPLETED SUCCESS":
            yield BuildCompleted(BuildStatus.SUCCESS)
        else:
            raise RuntimeError(f"Unrecognized notification: {message}")


def write_one(output, notification):
    if notification == BuildStarted():
        output.write("IBAZEL_BUILD_STARTED")
    elif notification == BuildCompleted(BuildStatus.FAILURE):
        output.write("IBAZEL_BUILD_COMPLETED FAILURE")
    elif notification == BuildCompleted(BuildStatus.SUCCESS):
        output.write("IBAZEL_BUILD_COMPLETED SUCCESS")
    else:
        raise RuntimeError(f"Unrecognized notification: {notification}")
    output.write("\n")
    output.flush()
