from pathlib import Path
from os import walk


def find_packages(root, roots, prefix, exclude_directories):
    for root_dir in roots:
        for package in sorted(_packages(root / root_dir, exclude_directories), key=str):
            package = package.relative_to(root)
            print(
                prefix
                if str(package) == "."
                else f"{prefix}/{package}"
                if prefix
                else package
            )


# https://github.com/bazelbuild/bazel/blob/4c2d91e762ab6e492853b021408129dd93fb5904/src/main/java/com/google/devtools/build/lib/skyframe/BazelSkyframeExecutorConstants.java#L30
_build_paths = ("BUILD", "BUILD.bazel")


def _packages(root, exclude_directories):
    for dir_, subdirs, files in walk(root):
        dir_ = Path(dir_)
        subdirs[:] = [
            d
            for d in subdirs
            if not any(
                (dir_ / d).full_match(exclude_directory)
                for exclude_directory in exclude_directories
            )
        ]
        if any(
            Path(file).full_match(build) for file in files for build in _build_paths
        ):
            yield Path(dir_)
