import requests
import re

# Raw base URL for modules
base_url = "https://raw.githubusercontent.com/nf-core/rnaseq/3.18.0/modules/nf-core/"
files = [
    "hisat2/align/main.nf",
    "fastqc/main.nf",
    "salmon/index/main.nf",
    "star/align/main.nf",
    "bbmap/bbsplit/main.nf",
    "bedtools/genomecov/main.nf",
    "bracken/bracken/main.nf",
    "cat/fastq/main.nf",
    "custom/catadditionalfasta/main.nf",
    "custom/getchromsizes/main.nf",
    "custom/tx2gene/main.nf",
    "dupradar/main.nf",
    "fastp/main.nf",
    "fq/lint/main.nf",
    "fq/subsample/main.nf",
    "gffread/main.nf",
    "gunzip/main.nf",
    "hisat2/align/main.nf",
    "hisat2/build/main.nf",
    "hisat2/extractsplicesites/main.nf",
    "kallisto/index/main.nf",
    "kallisto/quant/main.nf",
    "kraken2/kraken2/main.nf",
    "multiqc/main.nf",
    "picard/markduplicates/main.nf",
    "preseq/lcextrap/main.nf",
    "qualimap/rnaseq/main.nf",
    "rsem/calculateexpression/main.nf",
    "rsem/preparereference/main.nf",
    "rseqc/bamstat/main.nf"
    "rseqc/inferexperiment/main.nf",
    "rseqc/innerdistance/main.nf",
    "rseqc/junctionannotation/main.nf",
    "rseqc/junctionsaturation/main.nf",
    "rseqc/readdistribution/main.nf",
    "rseqc/readduplication/main.nf",
    "rseqc/tin/main.nf",
    "salmon/index/main.nf",
    "salmon/quant/main.nf",
    "samtools/flagstat/main.nf",
    "samtools/idxstats/main.nf",
    "samtools/index/main.nf",
    "samtools/sort/main.nf",
    "samtools/stats/main.nf",
    "sortmerna/main.nf",
    "star/genomegenerate/main.nf",
    "stringtie/stringtie/main.nf",
    "subread/featurecounts/main.nf",
    "summarizedexperiment/summarizedexperiment/main.nf",
    "trimgalore/main.nf",
    "tximeta/tximport/main.nf",
    "ucsc/bedclip/main.nf",
    "ucsc/bedgraphtobigwig/main.nf",
    "umicollapse/main.nf",
    "umitools/dedup/main.nf",
    "umitools/extract/main.nf",
    "umitools/prepareforrsem/main.nf",
    "untar/main.nf",
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
for m in metadata:
    print("\n" + "=" * 60)
    for key, val in m.items():
        print(f"{key}: {val}")
        
import json

# Save metadata to JSON file
output_path = "rnaseq.json"
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(metadata, f, indent=4)

print(f"\n✅ Metadata successfully saved to '{output_path}'")