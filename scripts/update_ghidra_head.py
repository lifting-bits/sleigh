"""Script to update CMake files for latest Ghidra Sleigh changes"""
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
from typing import AnyStr, Union

PROJECT_ROOT = pathlib.Path(__file__).parent.parent.resolve()
HEAD_SPEC_FILE = PROJECT_ROOT / "spec-files-list" / "spec_files_HEAD.cmake"
assert HEAD_SPEC_FILE.exists()
SETUP_GHIDRA_FILE = PROJECT_ROOT / "src" / "setup-ghidra-source.cmake"
assert SETUP_GHIDRA_FILE.exists()

GIT_EXE = shutil.which("git")
assert GIT_EXE is not None


def msg(s: str) -> None:
    print(f"[!] {s}")


PathString = Union[AnyStr, pathlib.Path]


def clone_ghidra_git(dir: PathString) -> None:
    """Clone the Ghidra git dir at specified directory"""
    # Shallow clone
    assert GIT_EXE is not None
    subprocess.run(
        [
            GIT_EXE,
            "clone",
            "https://github.com/NationalSecurityAgency/ghidra",
            "--depth",
            "1",
            dir,
        ],
        stdout=sys.stdout,
        stderr=sys.stderr,
        check=True,
    )


def update_head_commit(latest_commit: str):
    """Edit the Ghidra script to point to the latest commit"""
    head_commit_line = r"set\(ghidra_head_git_tag \"([0-9A-Fa-f]+)\"\)"
    updated = False

    fd, abspath = tempfile.mkstemp()
    with open(fd, "w") as w:
        with open(SETUP_GHIDRA_FILE, "r") as r:
            for line in r:
                match = re.search(head_commit_line, line)
                if match is not None:
                    current_commit = match.group(1)
                    if current_commit != latest_commit:
                        msg(f"Found new commit: {latest_commit}")
                        line = re.sub(
                            head_commit_line,
                            f'set(ghidra_head_git_tag "{latest_commit}")',
                            line,
                        )
                        updated = True
                w.write(line)

    # Make the swap with the new content
    shutil.copymode(SETUP_GHIDRA_FILE, abspath)
    os.remove(SETUP_GHIDRA_FILE)
    shutil.move(abspath, SETUP_GHIDRA_FILE)
    return updated


def update_head_version_file(ghidra_root_dir: PathString) -> None:
    """Edit the Ghidra script to point to the latest version"""
    cmake_head_version_line = (
        r"set\(ghidra_head_version \"([0-9]+(\.[0-9]+)?(\.[0-9]+)?)\"\)"
    )

    with (ghidra_root_dir / "Ghidra" / "application.properties").open("r") as f:
        content = f.read()
        match = re.search(
            r"application.version=([0-9]+(\.[0-9]+)?(\.[0-9]+)?)", content
        )
        assert match is not None
        source_version = match.group(1)

    with SETUP_GHIDRA_FILE.open("r") as f:
        content = f.read()
        match = re.search(cmake_head_version_line, content)
        assert match is not None
        cmake_version = match.group(1)

    if cmake_version == source_version:
        msg(f"No new version bump")
        return

    msg(f"Found new version: {source_version}")
    fd, abspath = tempfile.mkstemp()
    with open(fd, "w") as w:
        with SETUP_GHIDRA_FILE.open("r") as r:
            for line in r:
                match = re.search(cmake_head_version_line, line)
                if match is not None:
                    line = re.sub(
                        cmake_head_version_line,
                        f'set(ghidra_head_version "{source_version}")',
                        line,
                    )
                w.write(line)

    # Make the swap with the new content
    shutil.copymode(SETUP_GHIDRA_FILE, abspath)
    os.remove(SETUP_GHIDRA_FILE)
    shutil.move(abspath, SETUP_GHIDRA_FILE)


def update_spec_files(ghidra_repo_dir: PathString, cmake_file: PathString):
    """Based on the files in the Ghidra repo, write an updated list of spec files."""
    spec_files = []
    for dirpath, _, fnames in os.walk(ghidra_repo_dir / "Ghidra" / "Processors"):
        for file in fnames:
            if file.endswith(".slaspec"):
                spec_files.append(
                    (pathlib.Path(dirpath) / file).relative_to(ghidra_repo_dir)
                )
    assert len(spec_files) > 0
    spec_files.sort()

    msg(f"Found {len(spec_files)} slaspec files")

    with open(cmake_file, "w") as f:
        f.write("set(spec_file_list\n")
        for spec in spec_files:
            f.write(f'  "${{ghidrasource_SOURCE_DIR}}/{spec}"\n')
        f.write(")\n")


def get_latest_commit(ghidra_repo_dir: PathString) -> str:
    """Get the commit SHA that the repo is currently at"""
    assert GIT_EXE is not None
    return (
        subprocess.run(
            [GIT_EXE, "rev-parse", "HEAD"],
            cwd=ghidra_repo_dir,
            capture_output=True,
            check=True,
        )
        .stdout.decode()
        .strip()
    )


def update_head(ghidra_repo_dir: PathString, ci: bool) -> bool:
    """Update to latest head and make changes to the CMake files"""
    tmpdirname = None
    if ghidra_repo_dir is None:
        tmpdirname = tempfile.TemporaryDirectory()
        ghidra_repo_dir = pathlib.Path(tmpdirname.name) / "ghidra"
        clone_ghidra_git(ghidra_repo_dir)

    latest_commit = get_latest_commit(ghidra_repo_dir)
    did_update_commit = update_head_commit(latest_commit)
    if did_update_commit:
        if ci:
            print(f"::set-output name=short_sha::{latest_commit[:9]}")
            print("::set-output name=did_update::true")
        update_spec_files(ghidra_repo_dir, HEAD_SPEC_FILE)
        update_head_version_file(ghidra_repo_dir)
    else:
        msg(f"Already at the latest commit: {latest_commit}")

    if tmpdirname is not None:
        tmpdirname.cleanup()

    if did_update_commit:
        return True
    else:
        return False


if __name__ == "__main__":
    import argparse, os

    def dir_path(string):
        if string is None:
            return string
        string = pathlib.Path(string).expanduser().resolve()
        if string.is_dir():
            return string
        else:
            raise NotADirectoryError(string)

    parser = argparse.ArgumentParser(
        description="Update CMake files to latest Ghidra commit."
    )
    parser.add_argument(
        "--ghidra-repo",
        type=dir_path,
        help="Use a specific Ghidra repo directory instead of downloading it from the internet",
    )
    parser.add_argument(
        "--ci",
        action="store_true",
        help="Output GitHub Actions commands for recording information in CI",
    )
    args = parser.parse_args()

    if not update_head(args.ghidra_repo, args.ci):
        msg("No update required")
