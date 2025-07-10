```
// this process converts bedGraph files to bigWig format using UCSC tool
process UCSC_BEDGRAPHTOBIGWIG {
    // tag for identification of the process
    tag "$meta.id"
    // label for categorizing the process as single
    label 'process_single'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    // specifies the conda environment required for the process
    conda "${moduleDir}/environment.yml"
    // selects the appropriate container based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ucsc-bedgraphtobigwig:469--h9b8f530_0' :
        'biocontainers/ucsc-bedgraphtobigwig:469--h9b8f530_0' }"

    // input section defining the expected inputs for the process
    input:
    // a tuple that includes metadata and the path to the bedgraph file
    tuple val(meta), path(bedgraph)
    // path to the sizes file
    path  sizes

    // output section defining the expected outputs from the process
    output:
    // a tuple that includes metadata and the path to the generated bigWig file, with an emit directive for bigwig
    tuple val(meta), path("*.bigWig"), emit: bigwig
    // path to the versions file, with an emit directive for versions
    path "versions.yml"              , emit: versions

    // conditional section to determine when the process should run
    when:
    // checks if a custom condition is provided or defaults to true
    task.ext.when == null || task.ext.when

    // script section containing the commands to execute
    script:
    // assigns command-line arguments or defaults to an empty string
    def args = task.ext.args ?: ''
    // assigns a prefix or defaults to the metadata ID
    def prefix = task.ext.prefix ?: "${meta.id}"
    // specifies the version for the UCSC tool
    def VERSION = '469' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    // command to convert bedGraph to bigWig format
    bedGraphToBigWig \\
        $bedgraph \\
        $sizes \\
        ${prefix}.bigWig

    // outputting version information to the versions.yml file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc: $VERSION
    END_VERSIONS
    """

    // stub section for testing or placeholder functionality
    stub:
    // assigns a prefix or defaults to the metadata ID
    def prefix = task.ext.prefix ?: "${meta.id}"
    // specifies the version for the UCSC tool
    def VERSION = '469' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    // creates an empty bigWig file for the prefix
    touch ${prefix}.bigWig

    // outputting version information to the versions.yml file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc: $VERSION
    END_VERSIONS
    """
}
```