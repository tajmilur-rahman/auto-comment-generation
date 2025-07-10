import json
import os
from open_ai_api import generate_response

def read_json_file(file_path):
    """Read a JSON file and return its content as a list of dicts."""
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data


def convert_and_reverse_content(input_data):
    """Reverse the 'content' value for each item in the input list."""
    output_data = []
    for item in input_data:
        new_item = {
            'module_path': item['module_path'],
            'process_name': item['process_name'],
            'content': generate_response(item['content'])
        }
        output_data.append(new_item)
    print(f"Processed {len(output_data)} items.")
    return output_data


def write_json_file(file_path, data):
    """Write the list of dicts to a JSON file."""
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def main():
    input_path = os.path.join(os.path.dirname(__file__), '../data-set/rnaseq.json')
    output_path = os.path.join(os.path.dirname(__file__), '../data-set/rnaseq-output.json')
    input_data = read_json_file(input_path)
    output_data = convert_and_reverse_content(input_data)
    write_json_file(output_path, output_data)
    print(f"Output written to {output_path}")


if __name__ == "__main__":
    main()
