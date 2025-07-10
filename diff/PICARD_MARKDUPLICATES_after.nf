```
// this process marks duplicates in sequencing data using Picard tools
process PICARD_MARKDUPLICATES {
    // tag the process with metadata id
    tag "$meta.id"
    // label the process for identification
    label 'process_medium'

    // define the conda environment for the process
    conda "${moduleDir}/environment.yml"
    // specify the container image based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/picard:3.1.1--hdfd78af_0' :
        'biocontainers/picard:3.1.1--hdfd78af_0' }"

    // input section defining the required input files
    input:
    tuple val(meta), path(reads) // reads for processing
    tuple val(meta2), path(fasta) // reference fasta file
    tuple val(meta3), path(fai) // index file for the fasta

    // output section defining the generated output files
    output:
    tuple val(meta), path("*.bam") , emit: bam,  optional: true // BAM output file
    tuple val(meta), path("*.bai") , emit: bai,  optional: true // BAI output file
    tuple val(meta), path("*.cram"), emit: cram, optional: true // CRAM output file
    tuple val(meta), path("*.metrics.txt"), emit: metrics // metrics file
    path  "versions.yml"                  , emit: versions // file for versions information

    // conditional execution based on external task properties
    when:
    task.ext.when == null || task.ext.when

    // script section contains the main logic for processing
    script:
    def args = task.ext.args ?: '' // command line arguments for Picard
    def prefix = task.ext.prefix ?: "${meta.id}" // prefix for output files
    def suffix = task.ext.suffix    ?: "${reads.getExtension()}" // suffix for output files
    def reference = fasta ? "--REFERENCE_SEQUENCE ${fasta}" : "" // reference file argument
    def avail_mem = 3072 // default memory allocation
    if (!task.memory) {
        log.info '[Picard MarkDuplicates] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.' // log message for memory
    } else {
        avail_mem = (task.memory.mega*0.8).intValue() // calculate available memory
    }

    // check if input and output filenames are the same
    if ("$reads" == "${prefix}.${suffix}") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"

    // command to run the Picard MarkDuplicates tool
    """
    picard \\
        -Xmx${avail_mem}M \\
        MarkDuplicates \\
        $args \\
        --INPUT $reads \\
        --OUTPUT ${prefix}.${suffix} \\
        $reference \\
        --METRICS_FILE ${prefix}.MarkDuplicates.metrics.txt

    // create a versions file for logging tool versions
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(echo \$(picard MarkDuplicates --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """

    // stub section for potential placeholder functionality
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}" // prefix for output files in stub
    def suffix = task.ext.suffix    ?: "${reads.getExtension()}" // suffix for output files in stub
    // check if input and output filenames are the same in stub
    if ("$reads" == "${prefix}.${suffix}") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    // create placeholder files in stub
    """
    touch ${prefix}.${suffix}
    touch ${prefix}.MarkDuplicates.metrics.txt

    // create a versions file for logging tool versions in stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(echo \$(picard MarkDuplicates --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """
}
```