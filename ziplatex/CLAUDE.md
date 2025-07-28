# Claude.md - ziplatex Project Context

## Project Overview
ziplatex is a Go port of the bash script ziptex.sh that prepares LaTeX projects for journal submission by flattening all dependencies into a single archive.

## Key Design Decisions

### Why Go?
- Better UTF-8 handling than bash
- Single binary distribution
- Type safety and better error handling
- Cross-platform compatibility potential
- Good balance between performance and ease of development

### Architecture
The codebase is organized into four main files:
- `main.go` - CLI argument parsing and orchestration
- `latex.go` - LaTeX-specific operations (dependency finding, compilation checks, character detection)
- `fileops.go` - File operations and archive creation
- `checks.go` - Startup checks for required external tools

### Recent Improvements
- Removed hardcoded paths - now looks for .cls files in the current directory
- Added startup checks to verify pdflatex, latexpand, and bzip2 are installed
- Improved error messages to clearly indicate what went wrong
- Smart default output directory (checks if ~/Desktop exists, falls back to current directory)

### External Dependencies
The tool relies on standard LaTeX tools from MacTeX/TeX Live:
- `pdflatex` - For dependency detection and compilation checking
- `latexpand` - For flattening \input and \include statements
- `bzip2` - For creating tar.bz2 archives

## Common Tasks

### Building
```bash
go build
```

### Testing
```bash
# Run with a test LaTeX file
./ziplatex -z -o /tmp test.tex

# Test UTF-8 character detection
./ziplatex -z test_with_unicode.tex

# Force processing despite errors
./ziplatex -f -z problematic.tex
```

### Running Tests
```bash
go test ./...
```

## Known Issues and TODOs

### Current Limitations
1. No configuration file support
2. No parallel processing of multiple tex files
3. Limited to Unix-like systems (uses forward slashes)

### Potential Improvements
1. **Configuration File Support**
   - Add support for .ziplatexrc or ziplatex.toml
   - Allow custom class file paths
   - Define project-specific UTF-8 substitution rules

2. **Better UTF-8 Handling**
   - Automatic character substitution (e.g., smart quotes → straight quotes)
   - Support for different encodings
   - Option to convert files to ASCII-safe equivalents

3. **Performance**
   - Parallel processing of multiple tex files
   - Caching of dependency analysis
   - Progress bars for large projects

4. **Cross-platform Support**
   - Windows compatibility (path handling)
   - Portable archive creation without external bzip2

5. **Enhanced Error Recovery**
   - Partial processing mode
   - Better handling of missing dependencies
   - Automatic fixes for common issues

## Code Patterns

### Error Handling
The codebase uses Go's standard error return pattern. Most functions return an error as the last value:
```go
func someOperation() error {
    if err := doSomething(); err != nil {
        return fmt.Errorf("context: %v", err)
    }
    return nil
}
```

### File Processing
Files are processed in a temporary directory to avoid modifying the original project:
1. Copy files to temp directory
2. Process in temp directory
3. Create archive from temp directory
4. Clean up temp directory

### UTF-8 Character Detection
The tool parses pdflatex log files looking for font errors:
```
There is no X (U+XXXX) in font
```
Then searches for these characters in .tex, .bib, and .bbl files.

## Testing Approach
When making changes:
1. Test with simple single-file LaTeX documents first
2. Test with complex multi-file projects with bibliographies
3. Test with files containing UTF-8 characters
4. Test error cases (missing files, bad LaTeX, etc.)

## Debugging Tips
- Use `fmt.Printf` for debugging (remember to remove before committing)
- Check intermediate files in the LaTeX temp directory
- Compare output with original bash script for regression testing
- Use `pdflatex -interaction=nonstopmode` for debugging compilation issues

## Release Checklist
- [ ] Update version number
- [ ] Run tests
- [ ] Build for target platforms
- [ ] Update README if needed
- [ ] Tag release in git