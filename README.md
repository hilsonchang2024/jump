# jump

Windows `cmd` quick directory jump tool.

## Files

- `j.cmd`: main entry for `cmd.exe`
- `j-helper.ps1`: history read/write and fuzzy matching helper

## Install

1. Put this directory in `PATH`
2. Run:

```cmd
j --install
```

Open a new `cmd.exe` window after install.

## Usage

```cmd
j api
j cms
j -l
j -c
```

## Behavior

- Matches only the leaf directory name
- Prefers a match on the last token of the leaf name before falling back to older recent-first matches
- Most recently visited directory wins
- `cd`, `chdir`, `pushd`, `popd` are tracked after install

## Runtime files

- `j.history`: local history file, not intended for Git
