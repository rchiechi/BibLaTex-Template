package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
)

type Config struct {
	OutputDir    string
	TmpDir       string
	CreateZip    bool
	CreateBz2    bool
	Force        bool
	Debug        bool
	TexFiles     []string
}

func main() {
	config := parseArgs()
	
	if err := run(config); err != nil {
		log.Fatal(err)
	}
}

func parseArgs() Config {
	var config Config
	
	// Determine default output directory
	defaultOutput := filepath.Join(os.Getenv("HOME"), "Desktop")
	if _, err := os.Stat(defaultOutput); err != nil {
		// Desktop doesn't exist, use current directory
		defaultOutput, _ = os.Getwd()
	}
	
	flag.StringVar(&config.OutputDir, "o", defaultOutput, "Output directory")
	flag.BoolVar(&config.CreateZip, "z", false, "Create ZIP archive")
	flag.BoolVar(&config.CreateBz2, "j", false, "Create tar.bz2 archive")
	flag.BoolVar(&config.Force, "f", false, "Force operation even if LaTeX compilation fails")
	flag.BoolVar(&config.Debug, "debug", false, "Preserve temp directory for debugging")
	
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s [-f] [-z] [-j] [--debug] [-o OUTDIR] file.tex [file2.tex ...]\n", os.Args[0])
		flag.PrintDefaults()
	}
	
	flag.Parse()
	
	// Validate arguments
	if !config.CreateZip && !config.CreateBz2 {
		fmt.Fprintln(os.Stderr, "Error: You must pick at least one archive option, -z or -j.")
		flag.Usage()
		os.Exit(1)
	}
	
	if flag.NArg() == 0 {
		flag.Usage()
		os.Exit(1)
	}
	
	// Get tex files from remaining arguments
	config.TexFiles = flag.Args()
	
	// Set default values
	config.TmpDir = "LaTeX"
	// CustomClass will be empty by default - catClass will look for it locally
	
	// Convert output dir to absolute path
	absOut, err := filepath.Abs(config.OutputDir)
	if err != nil {
		log.Fatalf("Error resolving output directory: %v", err)
	}
	config.OutputDir = absOut
	
	// Check if output directory exists
	if info, err := os.Stat(config.OutputDir); err != nil || !info.IsDir() {
		log.Fatalf("Output directory does not exist: %s", config.OutputDir)
	}
	
	return config
}

func run(config Config) error {
	// Check required tools are available
	printBlue("Checking required tools...\n")
	if err := checkRequirements(config.CreateBz2); err != nil {
		return err
	}
	
	// Check if temp directory already exists
	if _, err := os.Stat(config.TmpDir); err == nil {
		return fmt.Errorf("temp directory %s already exists - please remove it or use a different name", config.TmpDir)
	}
	
	// Create temp directory
	if err := os.MkdirAll(config.TmpDir, 0755); err != nil {
		return fmt.Errorf("error creating temp directory: %v", err)
	}
	
	// Setup cleanup - only remove if not in debug mode
	if !config.Debug {
		defer os.RemoveAll(config.TmpDir)
	}
	
	// Process each tex file
	validTexFiles := []string{}
	allDeps := []string{}
	
	for _, texFile := range config.TexFiles {
		// Skip directories
		if info, err := os.Stat(texFile); err == nil && info.IsDir() {
			fmt.Printf("Skipping directory %s\n", texFile)
			continue
		}
		
		// Check if it's a tex file
		if !strings.HasSuffix(texFile, ".tex") {
			fmt.Printf("Skipping non-tex file %s\n", texFile)
			continue
		}
		
		printYellow("Processing %s\n", texFile)
		
		// Check for bad Unicode characters
		logFile := strings.TrimSuffix(texFile, ".tex") + ".log"
		if _, err := os.Stat(logFile); err == nil {
			badChars, err := findBadChars(logFile)
			if err == nil && len(badChars) > 0 {
				fmt.Printf("Found problematic characters in %s:\n", texFile)
				for _, char := range badChars {
					fmt.Printf("  Character '%s':\n", char)
					locations, _ := findBadCharLocations(char, ".")
					for _, loc := range locations {
						fmt.Printf("    %s\n", loc)
					}
				}
				if !config.Force {
					return fmt.Errorf("cannot continue processing %s due to bad characters", texFile)
				}
			}
		}
		
		// Find dependencies
		deps, err := findDeps(texFile)
		if err != nil {
			return fmt.Errorf("error finding dependencies for %s: %v", texFile, err)
		}
		
		// Copy tex file and dependencies to temp directory
		for _, dep := range deps {
			src := dep
			dst := filepath.Join(config.TmpDir, dep)
			
			// Preserve directory structure for now
			if err := os.MkdirAll(filepath.Dir(dst), 0755); err != nil {
				continue
			}
			
			if err := copyFile(src, dst); err != nil {
				fmt.Printf("Warning: could not copy %s: %v\n", src, err)
			} else {
				allDeps = append(allDeps, dep)
			}
		}
		
		// Check for bibliography
		if bibFile, err := extractBibliography(texFile); err == nil && bibFile != "" {
			if _, err := os.Stat(bibFile); err == nil {
				printPowderBlue("Adding bibliography %s\n", bibFile)
				if err := copyFile(bibFile, filepath.Join(config.TmpDir, bibFile)); err == nil {
					allDeps = append(allDeps, bibFile)
				}
			}
		}
		
		validTexFiles = append(validTexFiles, filepath.Base(texFile))
	}
	
	if len(validTexFiles) == 0 {
		return fmt.Errorf("no valid tex files to process")
	}
	
	// Change to temp directory for processing
	originalDir, _ := os.Getwd()
	if err := os.Chdir(config.TmpDir); err != nil {
		return fmt.Errorf("error changing to temp directory: %v", err)
	}
	defer os.Chdir(originalDir)
	
	// Flatten tex files
	printBlue("Flattening LaTeX files...\n")
	for _, texFile := range validTexFiles {
		bblFile := strings.TrimSuffix(texFile, ".tex") + ".bbl"
		if err := runLatexpand(texFile, bblFile); err != nil {
			fmt.Printf("Warning: latexpand failed for %s: %v\n", texFile, err)
		}
		// DEBUG: Copy file after latexpand for comparison
		if config.Debug {
			copyFile(texFile, texFile+".after_latexpand")
		}
	}
	
	// Concatenate aux files
	if err := catAux(validTexFiles); err != nil {
		fmt.Printf("Warning: error concatenating aux files: %v\n", err)
	}
	// DEBUG: Copy file after catAux for comparison
	if config.Debug {
		for _, texFile := range validTexFiles {
			copyFile(texFile, texFile+".after_cataux")
		}
	}
	
	// Concatenate class files
	if err := catClass(validTexFiles, ""); err != nil {
		fmt.Printf("Warning: error concatenating class files: %v\n", err)
	}
	// DEBUG: Copy file after catClass for comparison
	if config.Debug {
		for _, texFile := range validTexFiles {
			copyFile(texFile, texFile+".after_catclass")
		}
	}
	
	// Flatten directory structure
	if err := flattenDirs(validTexFiles); err != nil {
		fmt.Printf("Warning: error flattening directories: %v\n", err)
	}
	
	// Check if tex files compile
	printBlue("Checking LaTeX compilation...\n")
	allOk := true
	for _, texFile := range validTexFiles {
		if err := checkTex(texFile); err != nil {
			printRed("Error: %v\n", err)
			allOk = false
		} else {
			printGreen("%s compiles successfully\n", texFile)
		}
	}
	
	if !allOk && !config.Force {
		return fmt.Errorf("LaTeX compilation failed")
	}
	
	// Get final list of files to archive (AFTER all processing)
	// This matches the bash script behavior: run findDeps after flattening
	finalDeps := []string{}
	for _, texFile := range validTexFiles {
		deps, err := findDeps(texFile)
		if err == nil {
			finalDeps = append(finalDeps, deps...)
		}
	}
	
	// Add bib files
	bibFiles, _ := filepath.Glob("*.bib")
	finalDeps = append(finalDeps, bibFiles...)
	
	// Read .todel file to see what was concatenated and should be excluded
	toDelFiles := make(map[string]bool)
	if todelContent, err := ioutil.ReadFile(".todel"); err == nil {
		lines := strings.Split(string(todelContent), "\n")
		for _, line := range lines {
			line = strings.TrimSpace(line)
			if line != "" {
				toDelFiles[line] = true
				// Remove the actual files as bash script does
				printBlue("Cleaning up %s\n", line)
				os.Remove(line)
			}
		}
	}
	
	// Remove duplicates and filter out files that were concatenated or are .out files
	uniqueDeps := make(map[string]bool)
	filesToArchive := []string{}
	for _, dep := range finalDeps {
		if !uniqueDeps[dep] && !strings.HasSuffix(dep, ".out") && !toDelFiles[dep] {
			uniqueDeps[dep] = true
			filesToArchive = append(filesToArchive, dep)
		}
	}
	
	// Clean up temporary files
	os.Remove(".todel")
	// Remove .out and .bak files
	outFiles, _ := filepath.Glob("*.out")
	for _, f := range outFiles {
		os.Remove(f)
	}
	bakFiles, _ := filepath.Glob("*.bak")
	for _, f := range bakFiles {
		os.Remove(f)
	}
	
	// Change back to original directory for archive creation
	os.Chdir(originalDir)
	
	// Check if output archives already exist before creating them
	basename := filepath.Base(originalDir)
	
	if config.CreateZip {
		zipPath := filepath.Join(config.OutputDir, basename+".zip")
		if _, err := os.Stat(zipPath); err == nil {
			// Clean up temp directory before aborting
			if !config.Debug {
				os.RemoveAll(config.TmpDir)
			}
			return fmt.Errorf("output file already exists: %s\nPlease remove it or choose a different output directory", zipPath)
		}
	}
	
	if config.CreateBz2 {
		bz2Path := filepath.Join(config.OutputDir, basename+".tar.bz2")
		if _, err := os.Stat(bz2Path); err == nil {
			// Clean up temp directory before aborting
			if !config.Debug {
				os.RemoveAll(config.TmpDir)
			}
			return fmt.Errorf("output file already exists: %s\nPlease remove it or choose a different output directory", bz2Path)
		}
	}
	
	// Create archives
	if config.CreateZip {
		zipPath := filepath.Join(config.OutputDir, basename+".zip")
		printPowderBlue("Creating ZIP archive: %s\n", zipPath)
		
		// Update paths to be relative to temp dir, but only include files that actually exist
		zipFiles := []string{}
		for _, f := range filesToArchive {
			fullPath := filepath.Join(config.TmpDir, f)
			if _, err := os.Stat(fullPath); err == nil {
				zipFiles = append(zipFiles, fullPath)
			}
		}
		
		if err := createZipArchive(zipPath, zipFiles); err != nil {
			return fmt.Errorf("error creating zip archive: %v", err)
		}
	}
	
	if config.CreateBz2 {
		bz2Path := filepath.Join(config.OutputDir, basename+".tar.bz2")
		printPowderBlue("Creating tar.bz2 archive: %s\n", bz2Path)
		
		// Update paths to be relative to temp dir, but only include files that actually exist
		bz2Files := []string{}
		for _, f := range filesToArchive {
			fullPath := filepath.Join(config.TmpDir, f)
			if _, err := os.Stat(fullPath); err == nil {
				bz2Files = append(bz2Files, fullPath)
			}
		}
		
		if err := createBz2Archive(bz2Path, bz2Files); err != nil {
			return fmt.Errorf("error creating bz2 archive: %v", err)
		}
	}
	
	// Show debug information if in debug mode
	if config.Debug {
		// Get absolute path to temp directory
		absTmpDir, _ := filepath.Abs(config.TmpDir)
		
		fmt.Printf("\n=== DEBUG MODE ===\n")
		fmt.Printf("Temp directory preserved at: %s\n", absTmpDir)
		fmt.Printf("You can inspect the processed files and debug compilation issues.\n")
		fmt.Printf("\n*** IMPORTANT ***\n")
		fmt.Printf("You MUST remove this directory before running ziplatex again:\n")
		fmt.Printf("    rm -rf %s\n", config.TmpDir)
		fmt.Printf("Otherwise the next run will fail with 'temp directory already exists'.\n")
	}
	
	return nil
}