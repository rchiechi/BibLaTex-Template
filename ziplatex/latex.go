package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

// findDeps runs pdflatex with -record flag to find all dependencies
func findDeps(texFile string) ([]string, error) {
	cmd := exec.Command("pdflatex", "-draft", "-record", "-halt-on-error", "-interaction=nonstopmode", texFile)
	output, err := cmd.CombinedOutput()
	
	if err != nil {
		// Provide more context about what went wrong
		if strings.Contains(err.Error(), "executable file not found") {
			return nil, fmt.Errorf("pdflatex not found in PATH")
		}
		// If pdflatex ran but failed, include some output for debugging
		outputStr := string(output)
		if len(outputStr) > 1000 {
			// Show last 1000 chars which usually contain the error
			outputStr = "..." + outputStr[len(outputStr)-1000:]
		}
		return nil, fmt.Errorf("pdflatex failed for %s: %v\nOutput: %s", texFile, err, outputStr)
	}
	
	// Read the .fls file
	flsFile := strings.TrimSuffix(texFile, ".tex") + ".fls"
	content, err := ioutil.ReadFile(flsFile)
	if err != nil {
		return nil, fmt.Errorf("error reading .fls file: %v", err)
	}
	
	// Parse dependencies
	deps := []string{}
	seenDeps := make(map[string]bool)
	
	scanner := bufio.NewScanner(bytes.NewReader(content))
	for scanner.Scan() {
		line := scanner.Text()
		// Skip absolute paths, OUTPUT lines, and PWD lines
		if strings.HasPrefix(line, "INPUT /") ||
			strings.HasPrefix(line, "OUTPUT ") ||
			strings.HasPrefix(line, "PWD ") {
			continue
		}
		
		if strings.HasPrefix(line, "INPUT ") {
			dep := strings.TrimPrefix(line, "INPUT ")
			if !seenDeps[dep] {
				deps = append(deps, dep)
				seenDeps[dep] = true
			}
		}
	}
	
	return deps, nil
}

// checkTex verifies that a tex file compiles without errors
func checkTex(texFile string) error {
	cmd := exec.Command("pdflatex", "-draft", "-halt-on-error", "-interaction=nonstopmode", texFile)
	output, err := cmd.CombinedOutput()
	
	if err != nil {
		return fmt.Errorf("LaTeX compilation failed for %s:\n%s", texFile, string(output))
	}
	
	return nil
}

// findBadChars searches the log file for Unicode characters that break pdflatex
func findBadChars(logFile string) ([]string, error) {
	content, err := ioutil.ReadFile(logFile)
	if err != nil {
		return nil, err
	}
	
	// Look for "There is no X (U+XXXX) in font" patterns
	re := regexp.MustCompile(`There is no (.) \(.*?\) in font`)
	matches := re.FindAllStringSubmatch(string(content), -1)
	
	badChars := []string{}
	seen := make(map[string]bool)
	
	for _, match := range matches {
		if len(match) > 1 && !seen[match[1]] {
			badChars = append(badChars, match[1])
			seen[match[1]] = true
		}
	}
	
	return badChars, nil
}

// findBadCharLocations searches for bad characters in tex/bib files (not bbl)
func findBadCharLocations(badChar string, dir string) ([]string, error) {
	locations := []string{}

	patterns := []string{"*.tex", "*.bib"}
	for _, pattern := range patterns {
		files, err := filepath.Glob(filepath.Join(dir, pattern))
		if err != nil {
			continue
		}
		
		for _, file := range files {
			content, err := ioutil.ReadFile(file)
			if err != nil {
				continue
			}
			
			if strings.Contains(string(content), badChar) {
				// Find line numbers
				lines := strings.Split(string(content), "\n")
				for i, line := range lines {
					if strings.Contains(line, badChar) {
						locations = append(locations, fmt.Sprintf("%s:%d: %s", file, i+1, strings.TrimSpace(line)))
					}
				}
			}
		}
	}
	
	return locations, nil
}

// runLatexpand flattens the tex file using latexpand
func runLatexpand(texFile string, bblFile string) error {
	// Create temporary file
	tmpFile := texFile + "_tmp.tex"
	if err := os.Rename(texFile, tmpFile); err != nil {
		return fmt.Errorf("failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile)
	
	// Build latexpand command
	args := []string{"--verbose", "--fatal", "--expand-usepackage"}
	
	// Check if bbl file exists
	if bblFile != "" {
		if _, err := os.Stat(bblFile); err == nil {
			args = append(args, "--expand-bbl", bblFile)
		}
	}
	
	args = append(args, "-o", texFile, tmpFile)
	
	cmd := exec.Command("latexpand", args...)
	output, err := cmd.CombinedOutput()
	
	if err != nil {
		// Try to restore original file
		os.Rename(tmpFile, texFile)
		
		// Check for specific error types
		if strings.Contains(err.Error(), "executable file not found") {
			return fmt.Errorf("latexpand not found in PATH - it should be included with TeX Live")
		}
		
		return fmt.Errorf("latexpand failed to process %s: %v\nOutput: %s", texFile, err, string(output))
	}
	
	return nil
}

// extractBibliography finds bibliography references in tex file
func extractBibliography(texFile string) (string, error) {
	content, err := ioutil.ReadFile(texFile)
	if err != nil {
		return "", err
	}
	
	// Look for \bibliography{...} command
	re := regexp.MustCompile(`\\bibliography\{([^}]+)\}`)
	matches := re.FindStringSubmatch(string(content))
	
	if len(matches) > 1 {
		return matches[1] + ".bib", nil
	}
	
	return "", nil
}