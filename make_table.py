#!/usr/bin/env python3
import argparse
import csv
import json
import os
import sys

try:
    import pyperclip
except ImportError:
    pyperclip = None

def parse_data(file_path, comment_char='#', file_ext=None):
    """
    Reads and parses the first contiguous data block from a file,
    ignoring comments and empty lines.
    Detects file type from extension or content.
    """
    if file_ext is None:
        file_ext = os.path.splitext(file_path)[1].lower()

    data_lines = []
    in_data_block = False
    with open(file_path, 'r', newline='') as f:
        for line in f:
            stripped_line = line.strip()
            is_comment = stripped_line.startswith(comment_char)
            is_empty = not stripped_line

            if not is_comment and not is_empty:
                # This is a data line
                in_data_block = True
                data_lines.append(line)
            elif in_data_block and (is_comment or is_empty):
                # We were in a data block, but now we've hit a comment or empty line, so stop.
                break

    if not data_lines:
        return []  # No data found

    cleaned_content = "".join(data_lines)

    if file_ext in ['.csv', '.txt']:
        return parse_csv_content(cleaned_content)
    elif file_ext == '.json':
        # JSON files are typically a single block, so the "first block" logic
        # is less relevant, but we'll keep the parsing consistent.
        return parse_json_content(cleaned_content)
    else:
        # Attempt to auto-detect file type if extension is not standard
        try:
            # If the whole file is a valid JSON object, parse it as such.
            # The block-finding logic might not be ideal for JSON but works for CSV-like files.
            return parse_json_content(cleaned_content)
        except json.JSONDecodeError:
            # If JSON parsing fails, assume it's CSV-like
            return parse_csv_content(cleaned_content)


def parse_csv_content(content):
    """Parses pre-cleaned CSV string content."""
    try:
        # Use a sample of the content to sniff the delimiter
        dialect = csv.Sniffer().sniff(content[:2048])
    except csv.Error:
        # Fallback to comma if sniffing fails
        dialect = csv.excel
        dialect.delimiter = ','
        print("Warning: Could not detect CSV delimiter, falling back to comma.", file=sys.stderr)

    # Use the detected dialect to read the data
    reader = csv.reader(content.splitlines(), dialect)
    data = list(reader)

    # Check for consistent column count
    if not data:
        return []
    header_len = len(data[0])
    if not all(len(row) == header_len for row in data):
        raise ValueError("CSV rows have inconsistent number of columns.")
    return data

def parse_json_content(content):
    """Parses pre-cleaned JSON string content."""
    data = json.loads(content)
    if isinstance(data, list) and all(isinstance(row, list) for row in data):
        # Check for consistent column count
        if not data:
            return []
        header_len = len(data[0])
        if not all(len(row) == header_len for row in data):
            raise ValueError("JSON rows (from list of lists) have inconsistent number of columns.")
        return data
    elif isinstance(data, dict):
        # Convert dictionary of lists to list of lists (header + rows)
        header = list(data.keys())
        if not header:
            return []
        # Ensure all value lists have the same length
        val_iter = iter(data.values())
        try:
            first_len = len(next(val_iter))
            if not all(len(v) == first_len for v in val_iter if isinstance(v, (list, tuple))):
                raise ValueError("All lists in JSON object must be of the same length.")
        except StopIteration:
            return [header] # Handle empty dict values
        rows = list(zip(*data.values()))
        return [header] + rows
    else:
        raise ValueError("Unsupported JSON structure. Must be a list of lists or a dictionary of lists.")


def generate_latex_table(data, caption, label):
    """Generates a LaTeX table from a list of lists, escaping special characters."""
    if not data:
        return ""

    def escape_latex(s):
        """Escapes special LaTeX characters in a string."""
        s = str(s).strip()  # Strip whitespace and newlines
        # A dictionary of special LaTeX characters and their escaped versions.
        # Using raw strings (r'...') to prevent backslashes from being interpreted
        # as escape sequences by Python.
        chars = {
            '&': r'\&',
            '%': r'\%',
            '$': r'\$',
            '#': r'\#',
            '_': r'\_',
            '{': r'\{',
            '}': r'\}',
            '~': r'\textasciitilde{}',
            '^': r'\textasciicircum{}',
            '\\': r'\textbackslash{}'
        }
        return "".join([chars.get(c, c) for c in s])

    header = [escape_latex(h) for h in data[0]]
    body = [[escape_latex(item) for item in row] for row in data[1:]]
    num_columns = len(header)
    column_spec = ' '.join(['l'] * num_columns)

    latex_parts = []
    latex_parts.append(r"\begin{table}[htbp]")
    latex_parts.append(r"    \centering")
    if caption:
        latex_parts.append(f"    \\caption{{{escape_latex(caption)}}}")
    if label:
        latex_parts.append(f"    \\label{{{escape_latex(label)}}}")
    latex_parts.append(f"    \\begin{{tabular}}{{{column_spec}}}")
    latex_parts.append(r"        \hline")
    latex_parts.append("        " + " & ".join(header) + r" \\")
    latex_parts.append(r"        \hline")
    for row in body:
        latex_parts.append("        " + " & ".join(row) + r" \\")
    latex_parts.append(r"        \hline")
    latex_parts.append(r"    \end{tabular}")
    latex_parts.append(r"\end{table}")

    return "\n".join(latex_parts)

def main():
    """Main function to generate LaTeX table from a data file."""
    parser = argparse.ArgumentParser(
        description='Generate a LaTeX table from a CSV or JSON file, ignoring comments.',
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('input_file', help='Path to the input data file (CSV, JSON, TXT).')
    parser.add_argument('-o', '--output', help='Path to the output .tex file. Defaults to stdout.')
    parser.add_argument('-c', '--caption', help='Table caption.')
    parser.add_argument('-l', '--label', help='Table label.')
    parser.add_argument('--comment', default='#', help='Character used for comments (default: #).')
    args = parser.parse_args()

    try:
        data = parse_data(args.input_file, comment_char=args.comment)
    except FileNotFoundError:
        print(f"Error: Input file not found at '{args.input_file}'", file=sys.stderr)
        sys.exit(1)
    except (ValueError, csv.Error, json.JSONDecodeError) as e:
        print(f"Error processing file '{args.input_file}': {e}", file=sys.stderr)
        sys.exit(1)

    if not data:
        print("Warning: No data found in input file after filtering comments and empty lines.", file=sys.stderr)
        sys.exit(0)

    latex_table = generate_latex_table(data, args.caption, args.label)

    if args.output:
        try:
            with open(args.output, 'w') as f:
                f.write(latex_table)
            print(f"LaTeX table successfully written to {args.output}", file=sys.stderr)
        except IOError as e:
            print(f"Error writing to output file '{args.output}': {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print(latex_table)

    if pyperclip:
        try:
            pyperclip.copy(latex_table)
            print("\n---", file=sys.stderr)
            print("LaTeX output copied to clipboard.", file=sys.stderr)
        except pyperclip.PyperclipException as e:
            print(f"\n---", file=sys.stderr)
            print(f"Warning: Could not copy to clipboard: {e}", file=sys.stderr)
    else:
        print("\n---", file=sys.stderr)
        print("Warning: 'pyperclip' module not found.", file=sys.stderr)
        print("Please install it (`pip install pyperclip`) to enable copying to clipboard.", file=sys.stderr)

if __name__ == '__main__':
    main()