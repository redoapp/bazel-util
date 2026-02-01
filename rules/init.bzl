load("@rules_python//python:pip.bzl", "pip_parse")

def file_init():
    pip_parse(
        name = "pypi",
        python_interpreter_target = "@python_3_11_host//:python",
        requirements_lock = Label("//:requirements.txt"),
    )
