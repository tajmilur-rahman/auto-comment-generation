```
// this process handles the execution of the PRESEQ_LCEXTRAP workflow
process PRESEQ_LCEXTRAP {
    // assigns a unique identifier to the process
    tag "$meta.id"
    // labels the process for tracking
    label 'process_single'
    label 'error_retry'

    // specifies the conda environment to use for the process
    conda "${moduleDir}/environment.yml"
    // selects the appropriate container image based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/preseq:3.2.0--hdcf5f25_6':
        'biocontainers/preseq:3.2.0--hdcf5f25_6' }"

    // input section defines the expected input parameters for the process
    input:
    // accepts a tuple of metadata and a path to a BAM file
    tuple val(meta), path(bam)

    // output section defines the output produced by the process
    output:
    // outputs a tuple of metadata and the path to the extrapolated text file
    tuple val(meta), path("*.lc_extrap.txt"), emit: lc_extrap
    // outputs a tuple of metadata and the path to the log file
    tuple val(meta), path("*.log")          , emit: log
    // outputs the versions information to a YAML file
    path  "versions.yml"                    , emit: versions

    // when section defines the conditions under which the process should run
    when:
    task.ext.when == null || task.ext.when

    // script section contains the commands to be executed in the process
    script:
    // initializes arguments, allowing for optional task arguments
    def args = task.ext.args ?: ''
    // modifies arguments for subsequent attempts to disable defects testing
    args = task.attempt > 1 ? args.join(' -defects') : args  // Disable testing for defects
    // sets the output file prefix based on metadata or defaults to meta.id
    def prefix = task.ext.prefix ?: "${meta.id}"
    // determines if the input is paired-end based on metadata
    def paired_end = meta.single_end ? '' : '-pe'
    // command to run the preseq tool with the specified arguments
    """
    preseq \\
        lc_extrap \\
        $args \\
        $paired_end \\
        -output ${prefix}.lc_extrap.txt \\
        $bam
    // copies the error log to a command log with the prefix
    cp .command.err ${prefix}.command.log

    // writes version information to the versions.yml file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        preseq: \$(echo \$(preseq 2>&1) | sed 's/^.*Version: //; s/Usage:.*\$//')
    END_VERSIONS
    """

    // stub section provides a placeholder implementation for testing
    stub:
    // sets the output file prefix for the stub
    def prefix = task.ext.prefix ?: "${meta.id}"
    // creates empty output files for the stub
    """
    touch ${prefix}.lc_extrap.txt
    touch ${prefix}.command.log

    // writes version information to the versions.yml file in the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        preseq: \$(echo \$(preseq 2>&1) | sed 's/^.*Version: //; s/Usage:.*\$//')
    END_VERSIONS
    """
}
```