package main

import (
	"fmt"
	"os/exec"
	"strings"
)

// checkRequirements verifies that all required external tools are available
func checkRequirements(needsBzip2 bool) error {
	// Check pdflatex
	if err := checkTool("pdflatex", "--version"); err != nil {
		return fmt.Errorf("pdflatex not found or not working: %v\nPlease install MacTeX or TeX Live", err)
	}
	
	// Check latexpand
	if err := checkTool("latexpand", "--version"); err != nil {
		return fmt.Errorf("latexpand not found or not working: %v\nIt should be included with TeX Live", err)
	}
	
	// Check bzip2 if needed
	if needsBzip2 {
		if err := checkTool("bzip2", "--version"); err != nil {
			return fmt.Errorf("bzip2 not found or not working: %v\nPlease install bzip2", err)
		}
	}
	
	return nil
}

// checkTool verifies a command exists and can be executed
func checkTool(tool string, arg string) error {
	cmd := exec.Command(tool, arg)
	output, err := cmd.CombinedOutput()
	
	if err != nil {
		// Check if it's a "command not found" error
		if strings.Contains(err.Error(), "executable file not found") {
			return fmt.Errorf("command not found in PATH")
		}
		// Some tools exit with non-zero for --version, but that's OK if we got output
		if len(output) == 0 {
			return fmt.Errorf("command failed: %v", err)
		}
	}
	
	return nil
}

// getToolVersion returns version info for a tool (for debugging)
func getToolVersion(tool string, arg string) string {
	cmd := exec.Command(tool, arg)
	output, err := cmd.CombinedOutput()
	
	if err != nil && len(output) == 0 {
		return "unknown"
	}
	
	// Return first line of output
	lines := strings.Split(string(output), "\n")
	if len(lines) > 0 {
		return strings.TrimSpace(lines[0])
	}
	
	return "unknown"
}