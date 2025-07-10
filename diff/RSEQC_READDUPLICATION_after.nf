```
// this process performs read duplication analysis using RSEQC
process RSEQC_READDUPLICATION {
    // tag for identifying the process instance
    tag "$meta.id"
    // label for categorizing the process
    label 'process_medium'

    // specifies the conda environment to use
    conda "${moduleDir}/environment.yml"
    // defines the container to run the process, based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/rseqc:5.0.3--py39hf95cd2a_0' :
        'biocontainers/rseqc:5.0.3--py39hf95cd2a_0' }"

    // input section specifying the data to be processed
    input:
    tuple val(meta), path(bam)

    // output section defining the results produced by the process
    output:
    tuple val(meta), path("*seq.DupRate.xls"), emit: seq_xls
    tuple val(meta), path("*pos.DupRate.xls"), emit: pos_xls
    tuple val(meta), path("*.pdf")           , emit: pdf
    tuple val(meta), path("*.r")             , emit: rscript
    path  "versions.yml"                     , emit: versions

    // condition under which the process will run
    when:
    task.ext.when == null || task.ext.when

    // script section containing the commands to execute for processing
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    read_duplication.py \\
        -i $bam \\
        -o $prefix \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rseqc: \$(read_duplication.py --version | sed -e "s/read_duplication.py //g")
    END_VERSIONS
    """

    // stub section providing a placeholder implementation when the process is not executed
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.seq.DupRate.xls
    touch ${prefix}.pos.DupRate.xls
    touch ${prefix}.DupRate_plot.pdf
    touch ${prefix}.DupRate_plot.r

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rseqc: \$(read_duplication.py --version | sed -e "s/read_duplication.py //g")
    END_VERSIONS
    """
}
```