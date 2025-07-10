```
// this process creates a Kallisto index from a given FASTA file
process KALLISTO_INDEX {
    // set a tag for the process using the fasta variable
    tag "$fasta"
    // label the process with 'process_medium'
    label 'process_medium'

    // specify the conda environment to use
    conda "${moduleDir}/environment.yml"
    // define the container to be used based on the container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kallisto:0.51.1--heb0cbe2_0':
        'biocontainers/kallisto:0.51.1--heb0cbe2_0' }"

    // input section defining the expected inputs for the process
    input:
    // input a tuple with metadata and a path to the fasta file
    tuple val(meta), path(fasta)

    // output section defining what the process will produce
    output:
    // output a tuple with metadata and a path for the Kallisto index, emitting 'index'
    tuple val(meta), path("kallisto")  , emit: index
    // output a path for the versions file, emitting 'versions'
    path "versions.yml"                , emit: versions

    // condition under which the process will run
    when:
    // process will run if 'when' is null or true
    task.ext.when == null || task.ext.when

    // script section containing the commands to execute
    script:
    // define args variable, defaulting to an empty string if not provided
    def args = task.ext.args ?: ''
    """
    // command to run Kallisto index with provided args and fasta file
    kallisto \\
        index \\
        $args \\
        -i kallisto \\
        $fasta

    // create versions.yml file with the Kallisto version information
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kallisto: \$(echo \$(kallisto 2>&1) | sed 's/^kallisto //; s/Usage.*\$//')
    END_VERSIONS
    """

    // stub section for preparing the environment if the process is not executed
    stub:
    """
    // create the kallisto directory
    mkdir kallisto

    // create versions.yml file with the Kallisto version information
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kallisto: \$(echo \$(kallisto 2>&1) | sed 's/^kallisto //; s/Usage.*\$//')
    END_VERSIONS
    """
}
```