```
// this process indexes RNA sequences using Salmon
process SALMON_INDEX {
    // tags the process with the transcript fasta file
    tag "$transcript_fasta"
    // labels the process as medium
    label "process_medium"

    // specifies the conda environment to use
    conda "${moduleDir}/environment.yml"
    // selects the appropriate container based on the container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/salmon:1.10.3--h6dccd9a_2' :
        'biocontainers/salmon:1.10.3--h6dccd9a_2' }"

    // input section declaring required input files
    input:
    path genome_fasta
    path transcript_fasta

    // output section declaring emitted output files
    output:
    path "salmon"      , emit: index
    path "versions.yml", emit: versions

    // condition for when the task should run
    when:
    task.ext.when == null || task.ext.when

    // script section containing the main processing commands
    script:
    // initializes variable for additional arguments
    def args = task.ext.args ?: ''
    // command to extract decoy IDs from the genome fasta
    def get_decoy_ids = "grep '^>' $genome_fasta | cut -d ' ' -f 1 | cut -d \$'\\t' -f 1 > decoys.txt"
    // output filename for the concatenated genome and transcript fasta
    def gentrome      = "gentrome.fa"
    // checks if the genome fasta is gzipped and adjusts commands accordingly
    if (genome_fasta.endsWith('.gz')) {
        get_decoy_ids = "grep '^>' <(gunzip -c $genome_fasta) | cut -d ' ' -f 1 | cut -d \$'\\t' -f 1 > decoys.txt"
        gentrome      = "gentrome.fa.gz"
    }
    // commands to execute for the Salmon indexing process
    """
    $get_decoy_ids
    sed -i.bak -e 's/>//g' decoys.txt
    cat $transcript_fasta $genome_fasta > $gentrome

    salmon \\
        index \\
        --threads $task.cpus \\
        -t $gentrome \\
        -d decoys.txt \\
        $args \\
        -i salmon

    // creates a versions file with the Salmon version used
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salmon: \$(echo \$(salmon --version) | sed -e "s/salmon //g")
    END_VERSIONS
    """

    // stub section to create necessary output files
    stub:
    """
    // creates the salmon output directory and required files
    mkdir salmon
    touch salmon/complete_ref_lens.bin
    touch salmon/ctable.bin
    touch salmon/ctg_offsets.bin
    touch salmon/duplicate_clusters.tsv
    touch salmon/info.json
    touch salmon/mphf.bin
    touch salmon/pos.bin
    touch salmon/pre_indexing.log
    touch salmon/rank.bin
    touch salmon/refAccumLengths.bin
    touch salmon/ref_indexing.log
    touch salmon/reflengths.bin
    touch salmon/refseq.bin
    touch salmon/seq.bin
    touch salmon/versionInfo.json

    // creates a versions file with the Salmon version used
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salmon: \$(echo \$(salmon --version) | sed -e "s/salmon //g")
    END_VERSIONS
    """
}
```