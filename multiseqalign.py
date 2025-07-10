import requests
import re
import os

# Raw base URL for modules
base_url = "https://github.com/nf-core/multiplesequencealign/tree/1.1.1/modules/"
files = [
   "clustalo/align/main.nf",
   "clustalo/guidetree/main.nf",
   "csvtk/concat/main.nf",
   "csvtk/join/main.nf",
   "famsa/align/main.nf",
   "famsa/guidetree/main.nf",
   "fastavalidator/main.nf",
   "fastqc/main.nf",
   "foldmason/createdb/main.nf",
   "foldmason/easymsa/main.nf",
   "foldmason/msa2lddtreport/main.nf",
   "kalign/align/main.nf",
   "learnmsa/align/main.nf",
   "mafft/align/main.nf",
   "mafft/guidetree/main.nf",
   "magus/align/main.nf",
   "mtmalign/align/main.nf",
   "multiqc/main.nf",
   "muscle5/super5/main.nf",
   "pigz/compress/main.nf"
   "pigz/uncompress/main.nf",
   "tcoffee/align/main.nf",
   "tcoffee/alncompare/main.nf",
   "tcoffee/consensus/main.nf",
   "tcoffee/extractfrompdb/main.nf",
   "tcoffee/irmsd/main.nf",
   "tcoffee/regressive/main.nf",
   "tcoffee/seqreformat/main.nf",
   "tcoffee/tcs/main.nf",
   "untar/main.nf",
   "upp/align/main.nf"
    

    
]

# Patterns
patterns = {
    "process_name": re.compile(r"process\s+(\w+)", re.MULTILINE),
    "input": re.compile(r"input:\s*([\s\S]*?)(?=\n\s*(output:|script:|container:|label:))", re.MULTILINE),
    "output": re.compile(r"output:\s*([\s\S]*?)(?=\n\s*(script:|container:|label:))", re.MULTILINE),
    "script": re.compile(r"script:\s*(?P<quote>['\"]{3}|['\"])?([\s\S]*?)(?P=quote)?\s*$", re.MULTILINE),
    "container": re.compile(r"container\s*=\s*['\"]([^'\"]+)['\"]"),
    "label": re.compile(r"label\s+['\"]([^'\"]+)['\"]"),
    "publish_dir": re.compile(r"publishDir\s*:\s*path\((.*?)\)", re.MULTILINE)
}

metadata = []

for file in files:
    url = base_url + file
    print(f"Fetching {file}...")
    r = requests.get(url)
    if r.status_code != 200:
        print(f"⚠️ Could not fetch: {url}")
        continue

    content = r.text
    item = {
        "module_path": file,
        "process_name": patterns["process_name"].search(content).group(1) if patterns["process_name"].search(content) else "",
        "input": patterns["input"].search(content).group(1).strip() if patterns["input"].search(content) else "",
        "output": patterns["output"].search(content).group(1).strip() if patterns["output"].search(content) else "",
        "script": patterns["script"].search(content).group(2).strip() if patterns["script"].search(content) else "",
        "container": patterns["container"].search(content).group(1) if patterns["container"].search(content) else "",
        "label": patterns["label"].search(content).group(1) if patterns["label"].search(content) else "",
        "publishDir": patterns["publish_dir"].search(content).group(1).strip() if patterns["publish_dir"].search(content) else ""
    }
    metadata.append(item)

# ✅ Print metadata
for m in metadata:
    print("\n" + "=" * 60)
    for key, val in m.items():
        print(f"{key}: {val}")
        
import json

# Save metadata to JSON file
output_path = "multiseq_process_metadata.json"
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(metadata, f, indent=4)

print(f"\n✅ Metadata successfully saved to '{output_path}'")
