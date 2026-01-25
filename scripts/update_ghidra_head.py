#!/usr/bin/env python3
"""Script to update CMake files for latest Ghidra Sleigh changes"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Dict, Optional, Any, Tuple


# Constants
PROJECT_ROOT = Path(__file__).parent.parent.resolve()
HEAD_SPEC_FILE = PROJECT_ROOT / "src" / "spec_files_HEAD.cmake"
SETUP_GHIDRA_FILE = PROJECT_ROOT / "src" / "setup-ghidra-source.cmake"

# Paths in Ghidra repo that affect this repo
SLEIGH_PATHS = [
    "Ghidra/Features/Decompiler/src/decompile",  # Source code and tests
    "Ghidra/Processors",  # Sleigh files
]

# File extensions requiring manual CMake intervention
CPP_EXTENSIONS = {".cc", ".hh"}
SPEC_EXTENSIONS = {".slaspec", ".cspec", ".pspec", ".ldefs", ".opinion", ".sinc"}

# File extensions to ignore (in addition to .java)
IGNORED_EXTENSIONS = {
    ".java",
    ".gradle",
    ".properties",
    ".txt",
    ".md",
    ".html",
    ".xml",
    ".png",
    ".gif",
    ".jpg",
    ".ico",
}

# Paths for categorizing files
CPP_PATH = "Ghidra/Features/Decompiler/src/decompile/cpp/"
SPEC_PATH_PREFIX = "Ghidra/Processors/"

# Regex patterns
HEAD_COMMIT_PATTERN = r"set\(ghidra_head_git_tag \"([0-9A-Fa-f]+)\"\)"
VERSION_PATTERN = r"set\(ghidra_head_version \"([0-9]+(\.[0-9]+)*)\"\)"
APP_VERSION_PATTERN = r"application.version=([0-9]+(\.[0-9]+)*)"


@dataclass
class CategorizedChanges:
    """Holds files categorized by change type and file type."""

    added_cpp: List[str] = field(default_factory=list)
    deleted_cpp: List[str] = field(default_factory=list)
    added_spec: List[str] = field(default_factory=list)
    deleted_spec: List[str] = field(default_factory=list)

    def needs_manual_intervention(self) -> bool:
        """Check if any files need manual intervention."""
        return bool(
            self.added_cpp or self.deleted_cpp or self.added_spec or self.deleted_spec
        )

    def format_intervention_details(self) -> str:
        """Format the intervention details as markdown."""
        sections = []

        if self.added_cpp:
            sections.append("### New C++ Source Files")
            sections.append(
                "These files need to be added to `src/setup-ghidra-source.cmake`:"
            )
            for f in self.added_cpp:
                sections.append(f"- `{f}`")
            sections.append("")

        if self.deleted_cpp:
            sections.append("### Deleted C++ Source Files")
            sections.append(
                "These files need to be removed from `src/setup-ghidra-source.cmake`:"
            )
            for f in self.deleted_cpp:
                sections.append(f"- `{f}`")
            sections.append("")

        if self.added_spec:
            sections.append("### New Spec Files")
            sections.append(
                "Review if these files need manual CMake updates (`.slaspec` files "
                "are auto-generated; other types may need manual updates):"
            )
            for f in self.added_spec:
                sections.append(f"- `{f}`")
            sections.append("")

        if self.deleted_spec:
            sections.append("### Deleted Spec Files")
            sections.append("Verify these files are no longer referenced:")
            for f in self.deleted_spec:
                sections.append(f"- `{f}`")
            sections.append("")

        return "\n".join(sections).rstrip()


class GitHelper:
    """Helper class for Git operations"""

    def __init__(self) -> None:
        self.git_exe = shutil.which("git")
        if self.git_exe is None:
            raise RuntimeError("Git executable not found in PATH")

    def run(
        self, args: List[str], cwd: Path, capture_output: bool = False
    ) -> subprocess.CompletedProcess:
        """Run a git command with the given arguments"""
        assert self.git_exe is not None
        cmd = [self.git_exe] + args
        return subprocess.run(
            cmd,
            cwd=cwd,
            stdout=subprocess.PIPE if capture_output else sys.stdout,
            stderr=subprocess.PIPE if capture_output else sys.stderr,
            check=True,
            text=True if capture_output else False,
        )

    def clone(self, repo_url: str, target_dir: Path) -> None:
        """Clone a git repository"""
        print(f"Cloning {repo_url} to {target_dir}...")
        self.run(["clone", repo_url, str(target_dir)], cwd=PROJECT_ROOT)

    def get_head_commit(self, repo_dir: Path) -> str:
        """Get the HEAD commit SHA of the repository"""
        result = self.run(["rev-parse", "HEAD"], cwd=repo_dir, capture_output=True)
        return result.stdout.strip()

    def check_commit_exists(self, repo_dir: Path, commit: str) -> bool:
        """Check if a commit exists in the repository"""
        try:
            self.run(["cat-file", "-e", commit], repo_dir, capture_output=True)
            return True
        except subprocess.CalledProcessError:
            return False

    @staticmethod
    def _should_ignore_file(file_path: str) -> bool:
        """Check if a file should be ignored based on its extension."""
        ext = Path(file_path).suffix.lower()
        return ext in IGNORED_EXTENSIONS

    @staticmethod
    def _categorize_file(
        status: str, file_path: str, categorized: CategorizedChanges
    ) -> None:
        """Categorize a file based on its status and type.

        Args:
            status: Git status code (A, D, M, R, etc.)
            file_path: Path to the file
            categorized: CategorizedChanges object to update
        """
        ext = Path(file_path).suffix.lower()

        # Only categorize added (A) or deleted (D) files
        if status not in ("A", "D"):
            return

        # Check if it's a C++ file in the decompiler path
        if ext in CPP_EXTENSIONS and CPP_PATH in file_path:
            if status == "A":
                categorized.added_cpp.append(file_path)
            else:  # status == "D"
                categorized.deleted_cpp.append(file_path)
            return

        # Check if it's a spec file in the Processors path
        if ext in SPEC_EXTENSIONS and file_path.startswith(SPEC_PATH_PREFIX):
            if status == "A":
                categorized.added_spec.append(file_path)
            else:  # status == "D"
                categorized.deleted_spec.append(file_path)

    @staticmethod
    def _parse_git_status_line(line: str) -> Tuple[str, str, Optional[str]]:
        """Parse a git status line from --name-status output.

        Returns:
            Tuple of (status, file_path, new_path_for_rename)
        """
        parts = line.split("\t")
        status = parts[0]

        # Handle rename (R100 or similar)
        if status.startswith("R"):
            return ("R", parts[1], parts[2])

        return (status, parts[1], None)

    def get_commit_info(
        self, repo_dir: Path, old_commit: str, new_commit: str, paths: List[str]
    ) -> List[Dict[str, Any]]:
        """Get detailed information about commits affecting specified paths"""
        result = self.run(
            [
                "log",
                "--pretty=format:%H%n%ad%n%s%n%b%n====",
                "--date=iso",
                f"{old_commit}..{new_commit}",
                "--",
                *paths,
            ],
            cwd=repo_dir,
            capture_output=True,
        )

        log_output = result.stdout.strip()
        commits = []

        if log_output:
            commit_sections = log_output.split("\n====")

            for section in commit_sections:
                if not section.strip():
                    continue

                lines = section.strip().split("\n")
                commit_hash = lines[0]
                commit_date = lines[1]
                commit_msg = lines[2]
                body = "\n".join(lines[3:]) if len(lines) > 3 else ""

                # Get files modified in this commit
                files_result = self.run(
                    [
                        "diff-tree",
                        "--no-commit-id",
                        "--name-status",
                        "-r",
                        commit_hash,
                        "--",
                        *paths,
                    ],
                    cwd=repo_dir,
                    capture_output=True,
                )

                commit_files = files_result.stdout.strip().splitlines()
                # Filter out ignored files
                filtered_files = []
                for line in commit_files:
                    if not line.strip():
                        continue
                    status, file_path, new_path = self._parse_git_status_line(line)
                    if status == "R":
                        # For renames, check both old and new paths
                        if not self._should_ignore_file(file_path):
                            filtered_files.append(f"D\t{file_path}")
                        if new_path and not self._should_ignore_file(new_path):
                            filtered_files.append(f"A\t{new_path}")
                    elif not self._should_ignore_file(file_path):
                        filtered_files.append(line)
                commit_files = filtered_files

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

    def get_changed_files(
        self, repo_dir: Path, old_commit: str, new_commit: str, paths: List[str]
    ) -> Tuple[List[str], CategorizedChanges]:
        """Get list of files changed between commits and categorize them.

        Returns:
            Tuple of (filtered_files_list, categorized_changes)
        """
        result = self.run(
            [
                "diff",
                "--name-status",
                f"{old_commit}...{new_commit}",
                "--",
                *paths,
            ],
            cwd=repo_dir,
            capture_output=True,
        )

        raw_lines = result.stdout.strip().splitlines()
        filtered_files = []
        categorized = CategorizedChanges()

        for line in raw_lines:
            if not line.strip():
                continue

            status, file_path, new_path = self._parse_git_status_line(line)

            if status == "R":
                # For renames, treat as delete old + add new
                if not self._should_ignore_file(file_path):
                    filtered_files.append(f"D\t{file_path}")
                    self._categorize_file("D", file_path, categorized)
                if new_path and not self._should_ignore_file(new_path):
                    filtered_files.append(f"A\t{new_path}")
                    self._categorize_file("A", new_path, categorized)
            elif not self._should_ignore_file(file_path):
                filtered_files.append(line)
                self._categorize_file(status, file_path, categorized)

        return filtered_files, categorized


class GhidraUpdater:
    """Handles updating Ghidra-related CMake files"""

    def __init__(self, ci_mode: bool = False, dry_run: bool = False) -> None:
        self.git = GitHelper()
        self.ci_mode = ci_mode
        self.dry_run = dry_run

        # Validate required paths
        if not HEAD_SPEC_FILE.exists():
            raise FileNotFoundError(f"HEAD spec file not found: {HEAD_SPEC_FILE}")
        if not SETUP_GHIDRA_FILE.exists():
            raise FileNotFoundError(f"Setup Ghidra file not found: {SETUP_GHIDRA_FILE}")

        # Set up GitHub Actions outputs if in CI mode
        if self.ci_mode and "GITHUB_OUTPUT" not in os.environ:
            raise RuntimeError("CI mode requires GITHUB_OUTPUT environment variable")

    def clone_ghidra_if_needed(
        self, repo_dir: Optional[Path] = None
    ) -> Tuple[Path, Optional[tempfile.TemporaryDirectory]]:
        """Clone Ghidra repo if a directory is not provided"""
        temp_dir = None

        if repo_dir is None:
            temp_dir = tempfile.TemporaryDirectory()
            repo_dir = Path(temp_dir.name) / "ghidra"
            self.git.clone("https://github.com/NationalSecurityAgency/ghidra", repo_dir)

        return repo_dir, temp_dir

    def log_github_output(self, key: str, value: str) -> None:
        """Log output for GitHub Actions"""
        if self.ci_mode:
            with open(os.environ["GITHUB_OUTPUT"], "a") as f:
                f.write(f"{key}={value}\n")

    def log_github_multiline_output(self, key: str, value: str) -> None:
        """Log multiline output for GitHub Actions"""
        if self.ci_mode:
            with open(os.environ["GITHUB_OUTPUT"], "a") as f:
                f.write(f"{key}<<EOF\n")
                f.write(value)
                f.write("\nEOF\n")

    def display_changes(
        self, repo_dir: Path, start_commit: str, end_commit: str
    ) -> Tuple[List[str], List[Dict[str, Any]], CategorizedChanges]:
        """Display changes between two commits and return the changed files and commit info.

        Returns:
            Tuple of (changed_files, commit_info, categorized_changes)
        """
        # Get changed files and categorized changes
        changed_files, categorized = self.git.get_changed_files(
            repo_dir, start_commit, end_commit, SLEIGH_PATHS
        )

        if not changed_files:
            print("No sleigh files were modified between these commits")
            return [], [], CategorizedChanges()

        # Output changes for logging
        num_changed = len(changed_files)
        print(f"Found {num_changed} changed sleigh files:")
        for file in changed_files:
            print(f"  {file}")

        # Display manual intervention warning if needed
        if categorized.needs_manual_intervention():
            print("\n** Manual intervention may be required **")
            if categorized.added_cpp:
                print(f"  New C++ files: {len(categorized.added_cpp)}")
            if categorized.deleted_cpp:
                print(f"  Deleted C++ files: {len(categorized.deleted_cpp)}")
            if categorized.added_spec:
                print(f"  New spec files: {len(categorized.added_spec)}")
            if categorized.deleted_spec:
                print(f"  Deleted spec files: {len(categorized.deleted_spec)}")

        # Get detailed commit info for logging
        commit_info = self.git.get_commit_info(
            repo_dir, start_commit, end_commit, SLEIGH_PATHS
        )

        if commit_info:
            print(f"\nCommits affecting sleigh files ({len(commit_info)}):\n")
            for i, commit in enumerate(commit_info, 1):
                print(f"[Commit {i}/{len(commit_info)}]")
                print(f"Hash: {commit['hash']}")
                print(f"Date: {commit['date']}")
                print(f"Message: {commit['message']}")
                if commit["body"]:
                    print(f"Details:\n{commit['body']}")
                print("\nFiles changed:")
                for file in commit["files"]:
                    print(f"  {file}")
                print("")

        # Log outputs for GitHub Actions
        if self.ci_mode:
            self.log_github_output("short_sha", end_commit[:9])
            self.log_github_output("did_update", "true")

            # Log changed files
            changed_files_str = "```\n" + "\n".join(changed_files) + "\n```"
            self.log_github_multiline_output("changed_files", changed_files_str)

            # Log commit details
            if commit_info:
                details = ["```"]
                for i, commit in enumerate(commit_info, 1):
                    details.append(f"[Commit {i}/{len(commit_info)}]")
                    details.append(f"Hash: {commit['hash']}")
                    details.append(f"Date: {commit['date']}")
                    details.append(f"Message: {commit['message']}")
                    if commit["body"]:
                        details.append(f"Details:\n{commit['body']}")
                    details.append("\nFiles changed:")
                    for file in commit["files"]:
                        details.append(f"  {file}")
                    details.append("")
                # Replace trailing newline for last entry
                details[-1] = "```"

                self.log_github_multiline_output("commit_details", "\n".join(details))

            # Log manual intervention outputs
            if categorized.needs_manual_intervention():
                self.log_github_output("needs_manual_intervention", "true")
                self.log_github_multiline_output(
                    "intervention_details", categorized.format_intervention_details()
                )
            else:
                self.log_github_output("needs_manual_intervention", "false")

        return changed_files, commit_info, categorized

    def update_head_commit(
        self, repo_dir: Path, setup_file: Path
    ) -> Tuple[bool, str, str]:
        """Update the HEAD commit in the setup file if needed"""
        # Get latest commit hash
        latest_commit = self.git.get_head_commit(repo_dir)
        current_commit = None

        # Find current commit hash in setup file
        with setup_file.open("r") as f:
            for line in f:
                match = re.search(HEAD_COMMIT_PATTERN, line)
                if match:
                    current_commit = match.group(1)
                    break

        if current_commit is None:
            raise ValueError("Could not find current commit in setup file")

        # Check if update is needed
        if current_commit == latest_commit:
            print(f"Already at the latest commit: {latest_commit}")
            return False, current_commit, latest_commit

        print(f"Found new commit: {latest_commit}")

        # Check if sleigh files were updated and display changes
        changed_files, commit_info, _ = self.display_changes(
            repo_dir, current_commit, latest_commit
        )

        if not changed_files:
            return False, current_commit, latest_commit

        # Update the setup file if not in dry run mode
        if not self.dry_run:
            self._replace_in_file(
                setup_file,
                HEAD_COMMIT_PATTERN,
                f'set(ghidra_head_git_tag "{latest_commit}")',
            )

        return True, current_commit, latest_commit

    def update_version(self, repo_dir: Path, setup_file: Path) -> None:
        """Update the Ghidra version in the setup file if needed"""
        # Get source version from application.properties
        app_properties_file = repo_dir / "Ghidra" / "application.properties"

        with app_properties_file.open("r") as f:
            content = f.read()
            match = re.search(APP_VERSION_PATTERN, content)
            if not match:
                raise ValueError("Could not find version in application.properties")
            source_version = match.group(1)

        # Get current version from setup file
        with setup_file.open("r") as f:
            content = f.read()
            match = re.search(VERSION_PATTERN, content)
            if not match:
                raise ValueError("Could not find version in setup file")
            cmake_version = match.group(1)

        # Check if update is needed
        if cmake_version == source_version:
            print("No new version bump")
            return

        print(f"Found new version: {source_version}")

        # Update the setup file if not in dry run mode
        if not self.dry_run:
            self._replace_in_file(
                setup_file,
                VERSION_PATTERN,
                f'set(ghidra_head_version "{source_version}")',
            )

    def update_spec_files(self, repo_dir: Path, spec_file: Path) -> None:
        """Update the list of spec files in the CMake file"""
        # Find all .slaspec files
        spec_files = []
        processors_dir = repo_dir / "Ghidra" / "Processors"

        for path in processors_dir.glob("**/*.slaspec"):
            spec_files.append(path.relative_to(repo_dir))

        spec_files.sort()
        print(f"Found {len(spec_files)} slaspec files")

        # Write the updated spec file list
        if not self.dry_run and spec_files:
            with spec_file.open("w") as f:
                f.write("set(spec_file_list\n")
                for spec in spec_files:
                    f.write(f'  "${{ghidrasource_SOURCE_DIR}}/{spec}"\n')
                f.write(")\n")

    def _replace_in_file(self, file_path: Path, pattern: str, replacement: str) -> None:
        """Replace text in a file matching the pattern with the replacement"""
        temp_file = tempfile.NamedTemporaryFile(mode="w", delete=False)

        with file_path.open("r") as src, open(temp_file.name, "w") as dst:
            for line in src:
                dst.write(re.sub(pattern, replacement, line))

        # Replace the original file with the modified one
        shutil.copymode(file_path, temp_file.name)
        os.remove(file_path)
        shutil.move(temp_file.name, file_path)

    def update(self, repo_dir: Optional[Path] = None) -> bool:
        """Main update method to orchestrate the update process"""
        # Clone repo if not provided
        repo_dir, temp_dir = self.clone_ghidra_if_needed(repo_dir)

        try:
            # Update the HEAD commit
            did_update, _, _ = self.update_head_commit(repo_dir, SETUP_GHIDRA_FILE)

            # If commit was updated, also update version and spec files
            if did_update:
                self.update_version(repo_dir, SETUP_GHIDRA_FILE)
                self.update_spec_files(repo_dir, HEAD_SPEC_FILE)

            return did_update

        finally:
            # Clean up temp directory if created
            if temp_dir:
                temp_dir.cleanup()

    def compare_commits(
        self, repo_dir: Path, start_commit: str, end_commit: Optional[str] = None
    ) -> None:
        """Compare changes between two commits without updating any files"""
        # If end_commit is not provided, use HEAD
        if end_commit is None:
            end_commit = self.git.get_head_commit(repo_dir)
            print(f"Using HEAD as end commit: {end_commit}")

        print(f"Comparing commits {start_commit} to {end_commit}")

        # Check if the commits exist
        for commit in [start_commit, end_commit]:
            if not self.git.check_commit_exists(repo_dir, commit):
                raise ValueError(f"Commit {commit} does not exist in the repository")

        # Display changes
        self.display_changes(repo_dir, start_commit, end_commit)


def parse_args() -> argparse.Namespace:
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="Find and collect changes between two Ghidra commits. Update CMake files to latest Ghidra commit if specified."
    )

    parser.add_argument(
        "--ghidra-repo",
        type=str,
        help="Use a specific Ghidra repo directory instead of downloading it from the internet",
    )

    parser.add_argument(
        "--ci",
        action="store_true",
        help="Output GitHub Actions commands for recording information in CI. Requires GITHUB_OUTPUT environment variable.",
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without actually modifying any files",
    )

    parser.add_argument(
        "start_commit",
        nargs="?",
        type=str,
        help="Starting commit for comparison. When specified, no CMake files will be updated.",
    )

    parser.add_argument(
        "end_commit",
        nargs="?",
        type=str,
        help="Ending commit for comparison. If not specified, uses current HEAD of the repo. Requires start_commit.",
    )

    args = parser.parse_args()

    # Convert ghidra-repo path if provided
    if args.ghidra_repo:
        repo_path = Path(args.ghidra_repo).expanduser().resolve()
        if not repo_path.is_dir():
            parser.error(f"Ghidra repo directory does not exist: {repo_path}")
        args.ghidra_repo = repo_path

    # Validate commit arguments
    if args.end_commit and not args.start_commit:
        parser.error("Cannot specify end_commit without start_commit")

    # If commits are specified, a Ghidra repo is required
    if args.start_commit and not args.ghidra_repo:
        parser.error("--ghidra-repo is required when specifying commits")

    return args


def main() -> None:
    """Main entry point"""
    args = parse_args()

    try:
        updater = GhidraUpdater(ci_mode=args.ci, dry_run=args.dry_run)

        # If start_commit is specified, run in comparison mode
        if args.start_commit:
            updater.compare_commits(
                args.ghidra_repo, args.start_commit, args.end_commit
            )
        else:
            # Normal update mode
            did_update = updater.update(args.ghidra_repo)

            if not did_update:
                print("No update required")
            elif args.dry_run:
                print("Update would be required!")
            else:
                print("Update required!")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
