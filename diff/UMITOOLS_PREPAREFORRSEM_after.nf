```
// this process prepares UMI tools input for RSEM
process UMITOOLS_PREPAREFORRSEM {
    // assigns a tag based on the metadata ID
    tag "$meta.id"
    // labels the process as 'process_medium'
    label 'process_medium'

    // specifies the conda environment to use
    conda "${moduleDir}/environment.yml"
    // determines the container image to use based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/umi_tools:1.1.5--py39hf95cd2a_0' :
        'biocontainers/umi_tools:1.1.5--py39hf95cd2a_0' }"

    input:
    // defines the input variables: metadata, bam, and bai file paths
    tuple val(meta), path(bam), path(bai)

    output:
    // defines the output variables: bam file and log file paths
    tuple val(meta), path('*.bam'), emit: bam
    tuple val(meta), path('*.log'), emit: log
    // defines the output path for versions.yml file
    path  "versions.yml"          , emit: versions

    when:
    // specifies the condition for when to execute the process
    task.ext.when == null || task.ext.when

    script:
    // initializes arguments and prefix for output naming
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // checks for name collision between input and output
    if ("$bam" == "${prefix}.bam") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    // runs the umi_tools command to prepare for RSEM
    umi_tools prepare-for-rsem \\
        --stdin=$bam \\
        --stdout=${prefix}.bam \\
        --log=${prefix}.prepare_for_rsem.log \\
        $args

    // writes the tool version information to versions.yml
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        umitools: \$( umi_tools --version | sed '/version:/!d; s/.*: //' )
    END_VERSIONS
    """

    stub:
    // creates placeholder files for the output bam and log
    """
    touch ${meta.id}.bam
    touch ${meta.id}.log

    // writes the tool version information to versions.yml in the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        umitools: \$( umi_tools --version | sed '/version:/!d; s/.*: //' )
    END_VERSIONS
    """
}
```