```
// this process performs UCSC BEDClip operations
process UCSC_BEDCLIP {
    // assign a tag based on metadata ID
    tag "$meta.id"
    // set the label for the process
    label 'process_medium'

    // specify the conda environment for the process
    conda "${moduleDir}/environment.yml"
    // define the container to use based on the workflow container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ucsc-bedclip:377--h0b8a92a_2' :
        'biocontainers/ucsc-bedclip:377--h0b8a92a_2' }"

    input:
    // define input parameters including metadata and bedgraph file
    tuple val(meta), path(bedgraph)
    path  sizes

    output:
    // define output parameters including metadata and emitted bedGraph files
    tuple val(meta), path("*.bedGraph"), emit: bedgraph
    path "versions.yml"                , emit: versions

    when:
    // condition to determine when the process should run
    task.ext.when == null || task.ext.when

    script:
    // initialize arguments and prefix for output filenames
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // set the version of the tool being used
    def VERSION = '377' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    // command to run the bedClip tool with specified inputs
    bedClip \\
        $bedgraph \\
        $sizes \\
        ${prefix}.bedGraph

    // create a versions.yml file with version information
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc: $VERSION
    END_VERSIONS
    """

    stub:
    // initialize prefix and version for stub execution
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '377' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    // create an empty bedGraph file in the stub
    touch ${prefix}.bedGraph

    // create a versions.yml file with version information in the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc: $VERSION
    END_VERSIONS
    """
}
```