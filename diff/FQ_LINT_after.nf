```
// this process performs linting on FASTQ files
process FQ_LINT {
    // assigns a unique tag to the process based on metadata
    tag "$meta.id"
    // labels the process with a priority level
    label 'process_low'

    // specifies the conda environment to use for the process
    conda "${moduleDir}/environment.yml"
    // defines the container to run the process, choosing based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fq:0.12.0--h9ee0642_0':
        'biocontainers/fq:0.12.0--h9ee0642_0' }"

    // input section defining the expected input parameters
    input:
    // tuples containing metadata and path to the FASTQ file
    tuple val(meta), path(fastq)

    // output section defining the expected outputs of the process
    output:
    // tuples containing metadata and path to the lint result, emitting 'lint'
    tuple val(meta), path("*.fq_lint.txt"), emit: lint
    // path for versions output, emitting 'versions'
    path "versions.yml"                   , emit: versions

    // conditional execution section determining when to run the task
    when:
    // checks if the task should run based on the 'when' condition
    task.ext.when == null || task.ext.when

    // script section containing the main commands to execute
    script:
    // defines arguments and prefix for the output file
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // command to perform the linting and save the output
    """
    fq lint \\
        $args \\
        $fastq > ${prefix}.fq_lint.txt

    // command to save version information to a YAML file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fq: \$(echo \$(fq lint --version | sed 's/fq-lint //g'))
    END_VERSIONS
    """

    // stub section for testing without running the full process
    stub:
    // defines prefix for stub output
    def prefix = task.ext.prefix ?: "${meta.id}"
    // creates an empty output file and captures version information
    """
    touch ${prefix}.fq_lint.txt

    // command to save version information to a YAML file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fq: \$(echo \$(fq lint --version | sed 's/fq-lint //g'))
    END_VERSIONS
    """
}
```