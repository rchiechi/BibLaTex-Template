package main

import (
	"fmt"
	"os"
)

// ANSI color codes
const (
	ColorReset      = "\033[0m"
	ColorRed        = "\033[31m"
	ColorGreen      = "\033[32m"
	ColorYellow     = "\033[33m"
	ColorBlue       = "\033[34m"
	ColorLimeYellow = "\033[93m"  // Bright yellow
	ColorPowderBlue = "\033[96m"  // Bright cyan
)

// Color functions that match the bash script usage
func colorRed(text string) string {
	if !shouldUseColor() {
		return text
	}
	return ColorRed + text + ColorReset
}

func colorGreen(text string) string {
	if !shouldUseColor() {
		return text
	}
	return ColorGreen + text + ColorReset
}

func colorYellow(text string) string {
	if !shouldUseColor() {
		return text
	}
	return ColorYellow + text + ColorReset
}

func colorBlue(text string) string {
	if !shouldUseColor() {
		return text
	}
	return ColorBlue + text + ColorReset
}

func colorLimeYellow(text string) string {
	if !shouldUseColor() {
		return text
	}
	return ColorLimeYellow + text + ColorReset
}

func colorPowderBlue(text string) string {
	if !shouldUseColor() {
		return text
	}
	return ColorPowderBlue + text + ColorReset
}

// shouldUseColor checks if we should output colors
func shouldUseColor() bool {
	// Don't use colors if NO_COLOR environment variable is set
	if os.Getenv("NO_COLOR") != "" {
		return false
	}
	// Don't use colors if output is not a terminal
	if !isTerminal() {
		return false
	}
	return true
}

// isTerminal checks if stdout is a terminal
func isTerminal() bool {
	fileInfo, _ := os.Stdout.Stat()
	return (fileInfo.Mode() & os.ModeCharDevice) != 0
}

// Convenient print functions that match the bash script patterns
func printRed(format string, args ...interface{}) {
	fmt.Printf(colorRed(format), args...)
}

func printGreen(format string, args ...interface{}) {
	fmt.Printf(colorGreen(format), args...)
}

func printYellow(format string, args ...interface{}) {
	fmt.Printf(colorYellow(format), args...)
}

func printBlue(format string, args ...interface{}) {
	fmt.Printf(colorBlue(format), args...)
}

func printLimeYellow(format string, args ...interface{}) {
	fmt.Printf(colorLimeYellow(format), args...)
}

func printPowderBlue(format string, args ...interface{}) {
	fmt.Printf(colorPowderBlue(format), args...)
}