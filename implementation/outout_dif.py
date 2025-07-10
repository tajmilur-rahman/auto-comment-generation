import json
import os

def read_json_file(file_path):
    """Read a JSON file and return its content as a list of dicts."""
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data


def write_nf_file(file_path, content):
    """Write the content to a .nf file."""
    # Ensure the directory exists before writing
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)


def main():
    # Take user input for the index (n)
    base_dir = os.path.dirname(__file__)
    json1_path = os.path.join(base_dir, '../data-set/rnaseq.json')
    json2_path = os.path.join(base_dir, '../data-set/rnaseq-output.json')

    data1 = read_json_file(json1_path)
    data2 = read_json_file(json2_path)

    if len(data1) != len(data2):
        print(f"Invalid data length: first={len(data1)}, second={len(data2)}.")
        return
    
    maxLength = len(data1)

    for i in range(maxLength):
        content1 = data1[i]['content']
        content2 = data2[i]['content']

        process_name = data1[i]['process_name']
        file1_path = os.path.join(base_dir, '../diff', f'{process_name}_before.nf')
        file2_path = os.path.join(base_dir, '../diff', f'{process_name}_after.nf')

        write_nf_file(file1_path, content1)
        write_nf_file(file2_path, content2)

        print(f"{process_name}_before.nf and {process_name}_after.nf created for item {i}.")


if __name__ == "__main__":
    main()
