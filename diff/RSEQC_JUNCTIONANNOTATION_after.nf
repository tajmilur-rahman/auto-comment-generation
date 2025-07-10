```
// this process performs junction annotation using RSEQC
process RSEQC_JUNCTIONANNOTATION {
    // tags the process with metadata id
    tag "$meta.id"
    // labels the process with a specific label
    label 'process_medium'

    // specifies the conda environment for the process
    conda "${moduleDir}/environment.yml"
    // sets the container image based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/rseqc:5.0.3--py39hf95cd2a_0' :
        'biocontainers/rseqc:5.0.3--py39hf95cd2a_0' }"

    // defines the input parameters for the process
    input:
    // tuple containing metadata and path to BAM file
    tuple val(meta), path(bam)
    // path to the BED file
    path  bed

    // defines the output parameters for the process
    output:
    // tuple for the metadata and various output files
    tuple val(meta), path("*.xls")         , emit: xls
    tuple val(meta), path("*.r")           , emit: rscript
    tuple val(meta), path("*.log")         , emit: log
    tuple val(meta), path("*.junction.bed"), optional:true, emit: bed
    tuple val(meta), path("*.Interact.bed"), optional:true, emit: interact_bed
    tuple val(meta), path("*junction.pdf") , optional:true, emit: pdf
    tuple val(meta), path("*events.pdf")   , optional:true, emit: events_pdf
    path  "versions.yml"                   , emit: versions

    // conditional execution based on the presence of a 'when' parameter
    when:
    task.ext.when == null || task.ext.when

    // script to execute the junction annotation command
    script:
    // retrieves additional arguments and sets a prefix for output files
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    // command to run the junction annotation script with specified parameters
    junction_annotation.py \\
        -i $bam \\
        -r $bed \\
        -o $prefix \\
        $args \\
        2> >(grep -v 'E::idx_find_and_load' | tee ${prefix}.junction_annotation.log >&2)

    // create a versions.yml file capturing the version of the junction_annotation.py script
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rseqc: \$(junction_annotation.py --version | sed -e "s/junction_annotation.py //g")
    END_VERSIONS
    """

    // stub section to create output files without executing the process
    stub:
    // sets a prefix for output files
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    // creates placeholders for expected output files
    touch ${prefix}.junction.xls
    touch ${prefix}.junction_plot.r
    touch ${prefix}.junction_annotation.log
    touch ${prefix}.junction.bed
    touch ${prefix}.Interact.bed
    touch ${prefix}.junction.pdf
    touch ${prefix}.events.pdf

    // create a versions.yml file capturing the version of the junction_annotation.py script in the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rseqc: \$(junction_annotation.py --version | sed -e "s/junction_annotation.py //g")
    END_VERSIONS
    """
}
```