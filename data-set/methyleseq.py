import requests
import re
import os

# Raw base URL for modules
base_url = "https://raw.githubusercontent.com/nf-core/methylseq/refs/tags/4.0.0/modules/nf-core/"
files = [
    "bedtools/intersect/main.nf",
    "bismark/align/main.nf",
    "bismark/coverage2cytosine/main.nf",
    "bismark/deduplicate/main.nf",
    "bismark/genomepreparation/main.nf",
    "bismark/methylationextractor/main.nf",
    "bismark/report/main.nf",
    "bismark/summary/main.nf",
    "bwameth/align/main.nf",
    "bwameth/index/main.nf",
    "cat/fastq/main.nf",
    "fastqc/main.nf",
    "gunzip/main.nf",
    "methyldackel/extract/main.nf",
    "methyldackel/mbias/main.nf",
    "multiqc/main.nf",
    "parabricks/fq2bammeth/main.nf",
    "picard/bedtointervallist/main.nf",
    "picard/collecthsmetrics/main.nf",
    "picard/createsequencedictionary/main.nf",
    "picard/markduplicates/main.nf",
    "preseq/lcextrap/main.nf",
    "qualimap/bamqc/main.nf",
    "qualimap/bamqccram/main.nf",
    "samtools/faidx/main.nf",
    "samtools/flagstat/main.nf",
    "samtools/index/main.nf",
    "samtools/sort/main.nf",
    "samtools/stats/main.nf",
    "trimgalore/main.nf",
    "untar/main.nf"
]

# Patterns
patterns = {
    "process_name": re.compile(r"process\s+(\w+)", re.MULTILINE),
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
        "content": content,
    }
    metadata.append(item)

# ✅ Print metadata
# for m in metadata:
#     print("\n" + "=" * 60)
#     for key, val in m.items():
#         print(f"{key}: {val}")
        
import json

# Save metadata to JSON file
output_path = "methyleseq.json"
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(metadata, f, indent=4)

print(f"\n✅ Metadata successfully saved to '{output_path}'")