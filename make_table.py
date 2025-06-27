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

def parse_data(file_path, comment_char='#'):
    """
    Reads a file and splits it into a list of contiguous data blocks.
    """
    all_blocks = []
    current_block = []
    with open(file_path, 'r', newline='') as f:
        for line in f:
            stripped_line = line.strip()
            is_comment = stripped_line.startswith(comment_char)
            is_empty = not stripped_line

            if not is_comment and not is_empty:
                current_block.append(line)
            else:
                if current_block:
                    all_blocks.append("".join(current_block))
                    current_block = []
        if current_block:  # Add the last block if the file doesn't end with a newline
            all_blocks.append("".join(current_block))

    return all_blocks

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


def generate_latex_table(data, caption, label, round_digits=None):
    """
    Generates a LaTeX table from a list of lists, with options for rounding
    and formatting.
    """
    if not data:
        return ""

    def format_item(item):
        """Formats a single table item for LaTeX output."""
        item_str = str(item).strip()

        # Try to convert to a number for rounding and math mode
        try:
            # Try float conversion first
            num = float(item_str)
            if round_digits is not None:
                num = round(num, round_digits)
            # Format back to string, avoiding scientific notation for large/small numbers
            # if they are effectively integers after rounding.
            if num == int(num):
                item_str = str(int(num))
            else:
                item_str = f"{num:.{round_digits}f}"
            return f"${item_str}$"
        except (ValueError, TypeError):
            # Not a number, so just escape it
            return escape_latex(item_str)

    def escape_latex(s):
        """Escapes special LaTeX characters in a string."""
        chars = {
            '&': r'\&', '%': r'\%', '$': r'\$', '#': r'\#', '_': r'\_',
            '{': r'\{', '}': r'\}', '~': r'\textasciitilde{}',
            '^': r'\textasciicircum{}', '\\': r'\textbackslash{}'
        }
        return "".join([chars.get(c, c) for c in s])

    # Header is always treated as text and just escaped
    header = [escape_latex(h) for h in data[0]]
    # Body items are formatted
    body = [[format_item(item) for item in row] for row in data[1:]]
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
    latex_parts.append(r"        \\hline")
    latex_parts.append("        " + " & ".join(header) + r" \\")
    latex_parts.append(r"        \\hline")
    for row in body:
        latex_parts.append("        " + " & ".join(row) + r" \\")
    latex_parts.append(r"        \\hline")
    latex_parts.append(r"    \\end{tabular}")
    latex_parts.append(r"\end{table}")

    return "\n".join(latex_parts)

def main():
    """Main function to generate LaTeX table from a data file."""
    parser = argparse.ArgumentParser(
        description='Generate LaTeX tables from data blocks in a CSV or JSON file.',
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('input_file', help='Path to the input data file (CSV, JSON, TXT).')
    parser.add_argument('-o', '--output', help='Path to the output .tex file. Defaults to stdout.')
    parser.add_argument('-c', '--caption', help='Base table caption. A number will be appended for each table.')
    parser.add_argument('-l', '--label', help='Base table label. A number will be appended for each table.')
    parser.add_argument('--comment', default='#', help='Character used for comments (default: #).')
    parser.add_argument('--no-echo', action='store_true', help='Suppress stdout output.')
    parser.add_argument('--round', type=int, metavar='N', help='Round floats to N decimal places.')
    args = parser.parse_args()

    try:
        file_ext = os.path.splitext(args.input_file)[1].lower()
        data_blocks = parse_data(args.input_file, comment_char=args.comment)
    except FileNotFoundError:
        print(f"Error: Input file not found at '{args.input_file}'", file=sys.stderr)
        sys.exit(1)

    if not data_blocks:
        print("Warning: No data blocks found in input file.", file=sys.stderr)
        sys.exit(0)

    all_latex_tables = []
    for i, block_content in enumerate(data_blocks):
        try:
            if file_ext in ['.csv', '.txt']:
                data = parse_csv_content(block_content)
            elif file_ext == '.json':
                data = parse_json_content(block_content)
            else: # Auto-detect
                try:
                    data = parse_json_content(block_content)
                except json.JSONDecodeError:
                    data = parse_csv_content(block_content)

            if not data:
                continue

            # Create unique captions and labels for each table
            caption = f"{args.caption} (Table {i+1})" if args.caption else None
            label = f"{args.label}-{i+1}" if args.label else None

            latex_table = generate_latex_table(data, caption, label, args.round)
            all_latex_tables.append(latex_table)

        except (ValueError, csv.Error, json.JSONDecodeError) as e:
            print(f"Error processing data block {i+1} in '{args.f}': {e}", file=sys.stderr)
            continue # Skip bad blocks

    if not all_latex_tables:
        print("Warning: No valid data tables could be generated from the input file.", file=sys.stderr)
        sys.exit(0)

    final_output = "\n\n".join(all_latex_tables)

    if not args.no_echo:
        if args.output:
            try:
                with open(args.output, 'w') as f:
                    f.write(final_output)
                print(f"LaTeX table(s) successfully written to {args.output}", file=sys.stderr)
            except IOError as e:
                print(f"Error writing to output file '{args.output}': {e}", file=sys.stderr)
                sys.exit(1)
        else:
            print(final_output)

    if pyperclip:
        try:
            pyperclip.copy(final_output)
            print("LaTeX output copied to clipboard.", file=sys.stderr)
        except pyperclip.PyperclipException as e:
            print(f"Warning: Could not copy to clipboard: {e}", file=sys.stderr)
    else:
        print("Warning: 'pyperclip' module not found.", file=sys.stderr)
        print("Please install it (`pip install pyperclip`) to enable copying to clipboard.", file=sys.stderr)

if __name__ == '__main__':
    main()