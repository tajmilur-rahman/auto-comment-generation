```
// this process runs SAMTOOLS_STATS to generate statistics from input data
process SAMTOOLS_STATS {
    
    // tags the process with a unique identifier
    tag "$meta.id"
    
    // labels the process for identification
    label 'process_single'

    // specifies the conda environment for the process
    conda "${moduleDir}/environment.yml"
    
    // defines the container to be used based on the workflow container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    // input section defining the expected input data
    input:
    tuple val(meta), path(input), path(input_index)
    tuple val(meta2), path(fasta)

    // output section defining what data will be produced
    output:
    tuple val(meta), path("*.stats"), emit: stats
    path  "versions.yml"            , emit: versions

    // conditional execution based on the 'when' clause
    when:
    task.ext.when == null || task.ext.when

    // script section where the main processing commands are defined
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reference = fasta ? "--reference ${fasta}" : ""
    """
    samtools \\
        stats \\
        --threads ${task.cpus} \\
        ${reference} \\
        ${input} \\
        > ${prefix}.stats

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    // stub section to provide a placeholder execution
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.stats

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
```