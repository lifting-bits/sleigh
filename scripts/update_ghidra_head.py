"""Script to update CMake files for latest Ghidra Sleigh changes"""

import re
import shutil
import subprocess
import sys
import tempfile
import os
from pathlib import Path
from typing import AnyStr, Union, List, Dict

PROJECT_ROOT = Path(__file__).parent.parent.resolve()
HEAD_SPEC_FILE = PROJECT_ROOT / "src" / "spec_files_HEAD.cmake"
assert HEAD_SPEC_FILE.exists()
SETUP_GHIDRA_FILE = PROJECT_ROOT / "src" / "setup-ghidra-source.cmake"
assert SETUP_GHIDRA_FILE.exists()

# Paths in Ghidra repo that affect this repo. Used with git diff
SLEIGH_PATHS: List[str] = [
    # Source code and tests
    "Ghidra/Features/Decompiler/src/decompile",
    # Sleigh files
    "Ghidra/Processors",
]

GIT_EXE = shutil.which("git")
assert GIT_EXE is not None


def msg(s: str, end: str = "\n") -> None:
    print(f"[!] {s}", end=end)


PathString = Union[AnyStr, Path]


def clone_ghidra_git(clone_dir: PathString) -> None:
    """Clone the Ghidra git dir at specified directory"""
    assert GIT_EXE is not None
    subprocess.run(
        [
            GIT_EXE,
            "clone",
            "https://github.com/NationalSecurityAgency/ghidra",
            clone_dir,
        ],
        stdout=sys.stdout,
        stderr=sys.stderr,
        check=True,
    )


def git_get_commit_info(
    repo: Path, old_commit: str, new_commit: str, paths: List[str]
) -> List[Dict[str, str]]:
    """Get detailed information about commits that modified the specified paths"""
    assert GIT_EXE is not None
    log_output = (
        subprocess.run(
            [
                GIT_EXE,
                "log",
                "--pretty=format:%H%n%ad%n%s%n%b%n====",
                "--date=iso",
                f"{old_commit}..{new_commit}",
                "--",
                *paths,
            ],
            cwd=repo,
            capture_output=True,
            check=True,
        )
        .stdout.decode()
        .strip()
    )

    commits = []
    if log_output:
        commit_sections = log_output.split("\n====")
        # Process each commit
        for section in commit_sections:
            if not section.strip():
                continue
            lines = section.strip().split("\n")
            commit_hash = lines[0]
            commit_date = lines[1]
            commit_msg = lines[2]
            body = "\n".join(lines[3:]) if len(lines) > 3 else ""

            # Get the files modified in this commit
            commit_files = (
                subprocess.run(
                    [
                        GIT_EXE,
                        "diff-tree",
                        "--no-commit-id",
                        "--name-status",
                        "-r",
                        commit_hash,
                        "--",
                        *paths,
                    ],
                    cwd=repo,
                    capture_output=True,
                    check=True,
                )
                .stdout.decode()
                .strip()
                .splitlines()
            )

            # Filter out Java files
            commit_files = list(filter(lambda p: not p.endswith(".java"), commit_files))

            if commit_files:
                commits.append(
                    {
                        "hash": commit_hash,
                        "date": commit_date,
                        "message": commit_msg,
                        "body": body,
                        "files": commit_files,
                    }
                )

    return commits


def git_get_changed_files(
    repo: Path, old_commit: str, new_commit: str, paths: List[str], ci: bool
) -> List[str]:
    """Get list of changed files from old_commit to new_commit at the specified paths"""
    assert GIT_EXE is not None

    # Get all commits that change the relevant files
    commit_info = git_get_commit_info(repo, old_commit, new_commit, paths)

    # Also get the overall diff for summary
    changed_files = (
        subprocess.run(
            [
                GIT_EXE,
                "diff",
                "--name-status",
                f"{old_commit}...{new_commit}",
                "--",
                *paths,
            ],
            cwd=repo,
            capture_output=True,
            check=True,
        )
        .stdout.decode()
        .strip()
        .splitlines()
    )
    changed_files = list(filter(lambda p: not p.endswith(".java"), changed_files))
    num_changed = len(changed_files)

    if num_changed > 0:
        msg(f"Found {num_changed} changed sleigh files:")
        print("\n".join(changed_files))

        # Display detailed commit information
        if commit_info:
            msg(f"Commits affecting sleigh files ({len(commit_info)}):", "")
            for i, commit in enumerate(commit_info, 1):
                print(f"\n[Commit {i}/{len(commit_info)}]")
                print(f"Hash: {commit['hash']}")
                print(f"Date: {commit['date']}")
                print(f"Message: {commit['message']}")
                if commit["body"]:
                    print(f"Details:\n{commit['body']}")
                print("\nFiles changed:")
                for file in commit["files"]:
                    print(f"  {file}")

        if ci:
            with open(os.environ["GITHUB_OUTPUT"], "a") as gh_out:
                gh_out.write("changed_files<<EOF\n")
                gh_out.write("```\n")
                gh_out.write("\n".join(changed_files))
                gh_out.write("\n```\n")
                gh_out.write("EOF\n")

                if commit_info:
                    gh_out.write("commit_details<<EOF\n")
                    gh_out.write("```")
                    for i, commit in enumerate(commit_info, 1):
                        gh_out.write(f"\n[Commit {i}/{len(commit_info)}]\n")
                        gh_out.write(f"Hash: {commit['hash']}\n")
                        gh_out.write(f"Date: {commit['date']}\n")
                        gh_out.write(f"Message: {commit['message']}\n")
                        if commit["body"]:
                            gh_out.write(f"Details:\n{commit['body']}\n")
                        gh_out.write("\nFiles changed:\n")
                        for file in commit["files"]:
                            gh_out.write(f"  {file}\n")
                    gh_out.write("```\n")
                    gh_out.write("EOF\n")

    return changed_files


def is_sleigh_updated(
    ghidra_repo: Path, old_commit: str, new_commit: str, ci: bool
) -> bool:
    """Check if files we're interested in have been touched at all"""
    changed_files = git_get_changed_files(
        ghidra_repo, old_commit, new_commit, SLEIGH_PATHS, ci
    )
    return len(changed_files) > 0


def update_head_commit(
    setup_file: Path,
    ghidra_repo_dir: PathString,
    latest_commit: str,
    ci: bool,
    dry_run: bool = False,
) -> bool:
    """Edit the Ghidra script to point to the latest commit"""
    head_commit_line = r"set\(ghidra_head_git_tag \"([0-9A-Fa-f]+)\"\)"
    updated = False

    fd, abspath = tempfile.mkstemp()
    with open(fd, "w") as w:
        with setup_file.open("r") as r:
            for line in r:
                match = re.search(head_commit_line, line)
                if match is not None:
                    current_commit = match.group(1)
                    if current_commit != latest_commit:
                        msg(f"Found new commit: {latest_commit}")
                        if is_sleigh_updated(
                            ghidra_repo_dir, current_commit, latest_commit, ci
                        ):
                            if dry_run:
                                msg(
                                    f"Would update commit from {current_commit} to {latest_commit}"
                                )
                                updated = True
                            else:
                                line = re.sub(
                                    head_commit_line,
                                    f'set(ghidra_head_git_tag "{latest_commit}")',
                                    line,
                                )
                                updated = True
                        else:
                            msg("No sleigh files updated")
                w.write(line)

    # Make the swap with the new content
    if not dry_run:
        shutil.copymode(setup_file, abspath)
        os.remove(setup_file)
        shutil.move(abspath, setup_file)
    else:
        os.remove(abspath)  # Clean up the temp file in dry run mode
    return updated


def update_head_version_file(
    setup_file: Path, ghidra_root_dir: PathString, dry_run: bool = False
) -> None:
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

    with setup_file.open("r") as f:
        content = f.read()
        match = re.search(cmake_head_version_line, content)
        assert match is not None
        cmake_version = match.group(1)

    if cmake_version == source_version:
        msg("No new version bump")
        return

    msg(f"Found new version: {source_version}")
    if dry_run:
        msg(f"Would update version from {cmake_version} to {source_version}")
        return

    fd, abspath = tempfile.mkstemp()
    with open(fd, "w") as w:
        with setup_file.open("r") as r:
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
    shutil.copymode(setup_file, abspath)
    os.remove(setup_file)
    shutil.move(abspath, setup_file)


def update_spec_files(
    ghidra_repo_dir: PathString, cmake_file: PathString, dry_run: bool = False
):
    """Based on the files in the Ghidra repo, write an updated list of spec files."""
    spec_files = []
    for dirpath, _, fnames in os.walk(ghidra_repo_dir / "Ghidra" / "Processors"):
        for file in fnames:
            if file.endswith(".slaspec"):
                spec_files.append((Path(dirpath) / file).relative_to(ghidra_repo_dir))
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


def update_head(
    setup_file: Path,
    spec_file: Path,
    ghidra_repo_dir: PathString,
    ci: bool,
    dry_run: bool = False,
) -> bool:
    """Update to latest head and make changes to the CMake files"""
    tmpdirname = None
    if ghidra_repo_dir is None:
        tmpdirname = tempfile.TemporaryDirectory()
        ghidra_repo_dir = Path(tmpdirname.name) / "ghidra"
        clone_ghidra_git(ghidra_repo_dir)

    latest_commit = get_latest_commit(ghidra_repo_dir)
    did_update_commit = update_head_commit(
        setup_file, ghidra_repo_dir, latest_commit, ci, dry_run
    )
    if did_update_commit:
        if ci:
            with open(os.environ["GITHUB_OUTPUT"], "a") as gh_out:
                gh_out.write(f"short_sha={latest_commit[:9]}\n")
                gh_out.write("did_update=true\n")
        update_spec_files(ghidra_repo_dir, spec_file, dry_run)
        update_head_version_file(setup_file, ghidra_repo_dir, dry_run)
    else:
        msg(f"Already at the latest commit: {latest_commit}")

    if tmpdirname is not None:
        tmpdirname.cleanup()

    if did_update_commit:
        return True
    else:
        return False


if __name__ == "__main__":
    import argparse
    import os

    def dir_path(string):
        if string is None:
            return string
        string = Path(string).expanduser().resolve()
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
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without actually modifying any files",
    )
    args = parser.parse_args()

    if args.ci:
        assert "GITHUB_OUTPUT" in os.environ, (
            "CI needs `GITHUB_OUTPUT` environment variable set to a file location"
        )

    if not update_head(
        SETUP_GHIDRA_FILE, HEAD_SPEC_FILE, args.ghidra_repo, args.ci, args.dry_run
    ):
        msg("No update required")
    else:
        if args.dry_run:
            msg("Update would be required!")
        else:
            msg("Update required!")
