```
// this process runs SAMTOOLS_FLAGSTAT to generate flagstat statistics from BAM files
process SAMTOOLS_FLAGSTAT {
    // tags the process with an identifier
    tag "$meta.id"
    // assigns a label to the process for identification
    label 'process_single'

    // specifies the conda environment to use for the process
    conda "${moduleDir}/environment.yml"
    // defines the container to run the process, choosing based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    // input section defining the expected inputs for the process
    input:
    // takes a tuple of metadata, BAM file path, and BAI file path
    tuple val(meta), path(bam), path(bai)

    // output section defining the outputs of the process
    output:
    // emits a tuple containing metadata and the path to the flagstat file
    tuple val(meta), path("*.flagstat"), emit: flagstat
    // emits the path for the versions file
    path  "versions.yml"               , emit: versions

    // condition under which the process should run
    when:
    // process runs if the condition is null or true
    task.ext.when == null || task.ext.when

    // script section where the main command is defined
    script:
    // initializes arguments and prefix variables
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    // command to run samtools flagstat with specified options
    samtools \\
        flagstat \\
        --threads ${task.cpus} \\
        $bam \\
        > ${prefix}.flagstat

    // writes the versions used to a YAML file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    // stub section for testing or dry-run purposes
    stub:
    // initializes prefix variable for stub execution
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    // creates an empty flagstat file for the stub
    touch ${prefix}.flagstat

    // writes the versions used to a YAML file in the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
```