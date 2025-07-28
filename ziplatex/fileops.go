package main

import (
	"archive/tar"
	"archive/zip"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

// copyFile copies a file from src to dst
func copyFile(src, dst string) error {
	sourceFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sourceFile.Close()
	
	// Create destination directory if needed
	if err := os.MkdirAll(filepath.Dir(dst), 0755); err != nil {
		return err
	}
	
	destFile, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destFile.Close()
	
	_, err = io.Copy(destFile, sourceFile)
	return err
}

// catClass concatenates custom class files into tex files for portability
func catClass(texFiles []string, customClass string) error {
	printBlue("Looking for cls files to concatenate.\n")
	
	// Look for any .cls files in the current directory
	clsFiles, err := filepath.Glob("*.cls")
	if err != nil || len(clsFiles) == 0 {
		return nil // No class files found, skip
	}
	
	for _, texFile := range texFiles {
		content, err := ioutil.ReadFile(texFile)
		if err != nil {
			continue
		}
		
		// For each cls file, check if it's used in this tex file
		for _, clsFile := range clsFiles {
			className := strings.TrimSuffix(filepath.Base(clsFile), ".cls")
			
			// Check if this tex file uses this class
			if strings.Contains(string(content), "\\documentclass") && 
			   strings.Contains(string(content), className) {
				
				printLimeYellow("Concatenating %s into %s for portability\n", clsFile, texFile)
				
				// Read class file content
				classContent, err := ioutil.ReadFile(clsFile)
				if err != nil {
					fmt.Printf("Warning: error reading class file %s: %v\n", clsFile, err)
					continue
				}
				
				// Create new content with embedded class
				classContentStr := string(classContent)
				// Ensure class content ends with newline
				if !strings.HasSuffix(classContentStr, "\n") {
					classContentStr += "\n"
				}
				
				newContent := fmt.Sprintf("\\begin{filecontents}{%s}\n%s\\end{filecontents}\n%s",
					filepath.Base(clsFile),
					classContentStr,
					string(content))
				
				// Write back to tex file
				if err := ioutil.WriteFile(texFile, []byte(newContent), 0644); err != nil {
					return fmt.Errorf("error writing tex file: %v", err)
				}
				
				// Track file for deletion - add to .todel
				todelFile, _ := os.OpenFile(".todel", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
				fmt.Fprintf(todelFile, "%s\n", clsFile)
				todelFile.Close()
				
				// Reload content for next cls file check
				content = []byte(newContent)
			}
		}
	}
	
	return nil
}

// catAux concatenates aux files into tex files for portability
func catAux(texFiles []string) error {
	printBlue("Looking for aux files to concatenate.\n")
	
	for _, texFile := range texFiles {
		texContent, err := ioutil.ReadFile(texFile)
		if err != nil {
			continue
		}
		
		// For each tex file, look for corresponding aux file
		texBase := strings.TrimSuffix(filepath.Base(texFile), ".tex")
		auxFile := texBase + ".aux"
		
		// Check if the aux file exists
		if _, err := os.Stat(auxFile); err == nil {
			printLimeYellow("Concatenating %s into %s for portability\n", auxFile, texFile)
			
			auxContent, err := ioutil.ReadFile(auxFile)
			if err != nil {
				fmt.Printf("Warning: error reading aux file %s: %v\n", auxFile, err)
				continue
			}
			
			// Create new content with embedded aux
			auxContentStr := string(auxContent)
			// Ensure aux content ends with newline
			if !strings.HasSuffix(auxContentStr, "\n") {
				auxContentStr += "\n"
			}
			
			newContent := fmt.Sprintf("\\begin{filecontents}{%s}\n%s\\end{filecontents}\n%s",
				filepath.Base(auxFile),
				auxContentStr,
				string(texContent))
			
			if err := ioutil.WriteFile(texFile, []byte(newContent), 0644); err != nil {
				return fmt.Errorf("error writing tex file: %v", err)
			}
			
			// Track file for deletion - add to .todel
			todelFile, _ := os.OpenFile(".todel", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
			fmt.Fprintf(todelFile, "%s\n", auxFile)
			todelFile.Close()
			
			// Reload tex content for next iteration
			texContent = []byte(newContent)
		}
	}
	
	return nil
}

// flattenDirs flattens directory structure by moving graphics files
func flattenDirs(texFiles []string) error {
	for _, texFile := range texFiles {
		content, err := ioutil.ReadFile(texFile)
		if err != nil {
			continue
		}
		
		// Find graphicspath - handle double braces like \graphicspath{{figures/}}
		re := regexp.MustCompile(`\\graphicspath\{[^}]*\{([^}]+)\}[^}]*\}`)
		matches := re.FindStringSubmatch(string(content))
		
		if len(matches) > 1 {
			gfxPath := strings.Trim(matches[1], "{}")
			gfxPath = strings.TrimSuffix(gfxPath, "/")
			
			printLimeYellow("Flattening directory structure for %s\n", texFile)
			
			// Check if graphics path exists
			if info, err := os.Stat(gfxPath); err == nil && info.IsDir() {
				// Move all files from graphics path to current directory
				err := filepath.Walk(gfxPath, func(path string, info os.FileInfo, err error) error {
					if err != nil || info.IsDir() {
						return nil
					}
					
					// Move file to current directory
					destPath := filepath.Base(path)
					fmt.Printf("Moving %s to %s\n", path, destPath)
					return os.Rename(path, destPath)
				})
				
				if err != nil {
					fmt.Printf("Warning: error moving files from %s: %v\n", gfxPath, err)
				}
			} else {
				fmt.Printf("Warning: graphicspath \"%s\" not found\n", gfxPath)
			}
			
			// Remove the entire graphicspath command from tex file
			// Use a regex that matches the complete command including double braces
			replaceRe := regexp.MustCompile(`\\graphicspath\{[^}]*\{[^}]+\}[^}]*\}`)
			newContent := replaceRe.ReplaceAllString(string(content), "")
			if err := ioutil.WriteFile(texFile, []byte(newContent), 0644); err != nil {
				return fmt.Errorf("error updating tex file: %v", err)
			}
		}
	}
	
	// Remove empty directories
	dirs, _ := filepath.Glob("*/")
	for _, dir := range dirs {
		os.Remove(dir) // Will only succeed if empty
	}
	
	return nil
}

// createZipArchive creates a zip file with the specified files
func createZipArchive(outputPath string, files []string) error {
	zipFile, err := os.Create(outputPath)
	if err != nil {
		return err
	}
	defer zipFile.Close()
	
	zipWriter := zip.NewWriter(zipFile)
	defer zipWriter.Close()
	
	for _, file := range files {
		if err := addFileToZip(zipWriter, file); err != nil {
			return err
		}
	}
	
	return nil
}

func addFileToZip(zipWriter *zip.Writer, filename string) error {
	file, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer file.Close()
	
	info, err := file.Stat()
	if err != nil {
		return err
	}
	
	header, err := zip.FileInfoHeader(info)
	if err != nil {
		return err
	}
	
	header.Name = filename
	header.Method = zip.Deflate
	
	writer, err := zipWriter.CreateHeader(header)
	if err != nil {
		return err
	}
	
	_, err = io.Copy(writer, file)
	return err
}

// createBz2Archive creates a tar.bz2 file with the specified files
func createBz2Archive(outputPath string, files []string) error {
	// Create tar file first
	tarPath := strings.TrimSuffix(outputPath, ".bz2")
	tarFile, err := os.Create(tarPath)
	if err != nil {
		return err
	}
	defer tarFile.Close()
	defer os.Remove(tarPath) // Clean up tar file after compression
	
	tarWriter := tar.NewWriter(tarFile)
	
	for _, file := range files {
		if err := addFileToTar(tarWriter, file); err != nil {
			return err
		}
	}
	
	if err := tarWriter.Close(); err != nil {
		return err
	}
	tarFile.Close()
	
	// Compress with bzip2
	return compressBz2(tarPath, outputPath)
}

func addFileToTar(tarWriter *tar.Writer, filename string) error {
	file, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer file.Close()
	
	info, err := file.Stat()
	if err != nil {
		return err
	}
	
	header, err := tar.FileInfoHeader(info, "")
	if err != nil {
		return err
	}
	
	header.Name = filename
	
	if err := tarWriter.WriteHeader(header); err != nil {
		return err
	}
	
	_, err = io.Copy(tarWriter, file)
	return err
}

func compressBz2(inputPath, outputPath string) error {
	cmd := exec.Command("bzip2", "-c", inputPath)
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("bzip2 compression failed: %v", err)
	}
	
	return ioutil.WriteFile(outputPath, output, 0644)
}