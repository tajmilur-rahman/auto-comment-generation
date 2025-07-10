```
// this process calculates read distribution from BAM files using RSEQC
process RSEQC_READDISTRIBUTION {
    // assigns a unique tag to the process based on meta.id
    tag "$meta.id"
    // labels the process for easier identification
    label 'process_medium'

    // specifies the conda environment to use for the process
    conda "${moduleDir}/environment.yml"
    // selects the appropriate container based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/rseqc:5.0.3--py39hf95cd2a_0' :
        'biocontainers/rseqc:5.0.3--py39hf95cd2a_0' }"

    input:
    // defines the input as a tuple containing metadata and a path to the BAM file
    tuple val(meta), path(bam)
    // specifies an additional input path for the BED file
    path  bed

    output:
    // defines the output as a tuple containing metadata and a path for the read distribution text file
    tuple val(meta), path("*.read_distribution.txt"), emit: txt
    // specifies an additional output path for the versions file
    path  "versions.yml"                            , emit: versions

    when:
    // determines when to execute the process based on the task's 'when' condition
    task.ext.when == null || task.ext.when

    script:
    // initializes arguments and prefix variables for the script execution
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    // command to generate the read distribution output, redirecting to a text file
    read_distribution.py \\
        -i $bam \\
        -r $bed \\
        > ${prefix}.read_distribution.txt

    // creates a versions.yml file containing the version of read_distribution.py
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rseqc: \$(read_distribution.py --version | sed -e "s/read_distribution.py //g")
    END_VERSIONS
    """

    stub:
    // initializes prefix variable for the stub execution
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    // creates an empty read distribution text file as a placeholder
    touch ${prefix}.read_distribution.txt

    // creates a versions.yml file containing the version of read_distribution.py
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rseqc: \$(read_distribution.py --version | sed -e "s/read_distribution.py //g")
    END_VERSIONS
    """
}
```