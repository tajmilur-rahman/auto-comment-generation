// this process computes idxstats for BAM files using samtools
process SAMTOOLS_IDXSTATS {
    // assign a tag for the process
    tag "$meta.id"
    // assign a label to the process
    label 'process_single'

    // specify the conda environment to use
    conda "${moduleDir}/environment.yml"
    // determine the container image to use based on the workflow configuration
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    // input section defining the expected input types for the process
    input:
    tuple val(meta), path(bam), path(bai)

    // output section defining the expected output types from the process
    output:
    tuple val(meta), path("*.idxstats"), emit: idxstats
    path  "versions.yml"               , emit: versions

    // condition under which the process will run
    when:
    task.ext.when == null || task.ext.when

    // script section containing the main processing commands
    script:
    // define arguments and prefix for output filenames
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // command to run samtools idxstats and generate output files
    """
    samtools \\
        idxstats \\
        --threads ${task.cpus-1} \\
        $bam \\
        > ${prefix}.idxstats

    // create a versions file with the samtools version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    // stub section for simulating the process without actual execution
    stub:
    // define prefix for output filenames in the stub
    def prefix = task.ext.prefix ?: "${meta.id}"

    // commands to create placeholder output files in the stub
    """
    touch ${prefix}.idxstats

    // create a versions file with the samtools version in the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}