# ziplatex

A Go port of ziptex.sh that flattens LaTeX projects into publication-ready archives.

## Features

- Finds all LaTeX dependencies using pdflatex's `-record` flag
- Detects and reports problematic UTF-8 characters in .bbl and other files
- Flattens \input and \include statements using latexpand
- Embeds custom class files and aux files for portability
- Flattens directory structure (handles graphicspath)
- Creates ZIP and/or tar.bz2 archives

## Usage

```bash
ziplatex [-f] [-z] [-j] [--debug] [-o OUTDIR] file.tex [file2.tex ...]

Options:
  -f         Force operation even if LaTeX compilation fails
  -j         Create tar.bz2 archive
  -o string  Output directory (default "$HOME/Desktop" or current directory)
  -z         Create ZIP archive
  --debug    Preserve temp directory for debugging (shows path at end)
```

You must specify at least one archive format (-z or -j).

Note: Only .tex files are processed. Other file types (like .bib files) passed as arguments will be skipped. Bibliography files are automatically detected and included based on `\bibliography{}` commands in your tex files.

## Building

```bash
go build
```

## Requirements

- Go 1.16 or later
- MacTeX or TeX Live installation (for pdflatex, latexpand)
- bzip2 (for tar.bz2 creation)
