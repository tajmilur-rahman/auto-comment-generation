// this process counts features from genomic data using featureCounts
process SUBREAD_FEATURECOUNTS {
    // tag the process with a unique identifier
    tag "$meta.id"
    // assign a label for process categorization
    label 'process_medium'

    // specify the conda environment for the process
    conda "${moduleDir}/environment.yml"
    // define the container to be used based on the workflow engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/subread:2.0.6--he4a0461_2' :
        'biocontainers/subread:2.0.6--he4a0461_2' }"

    // input the metadata, BAM files, and annotation file
    input:
    tuple val(meta), path(bams), path(annotation)

    // output the counts and summary files along with versions
    output:
    tuple val(meta), path("*featureCounts.txt")        , emit: counts
    tuple val(meta), path("*featureCounts.txt.summary"), emit: summary
    path "versions.yml"                                , emit: versions

    // condition for when to execute the process
    when:
    task.ext.when == null || task.ext.when

    // script section where the main logic is executed
    script:
    // retrieve arguments, prefix, and paired-end option
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def paired_end = meta.single_end ? '' : '-p'

    // determine strandedness based on metadata
    def strandedness = 0
    if (meta.strandedness == 'forward') {
        strandedness = 1
    } else if (meta.strandedness == 'reverse') {
        strandedness = 2
    }
    // command to run featureCounts with the specified parameters
    """
    featureCounts \\
        $args \\
        $paired_end \\
        -T $task.cpus \\
        -a $annotation \\
        -s $strandedness \\
        -o ${prefix}.featureCounts.txt \\
        ${bams.join(' ')}

    // output versions of the featureCounts tool used
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        subread: \$( echo \$(featureCounts -v 2>&1) | sed -e "s/featureCounts v//g")
    END_VERSIONS
    """

    // stub section for creating placeholder files
    stub:
    // retrieve prefix for output files
    def prefix = task.ext.prefix ?: "${meta.id}"
    // create empty output files
    """
    touch ${prefix}.featureCounts.txt
    touch ${prefix}.featureCounts.txt.summary

    // output versions of the featureCounts tool used in the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        subread: \$( echo \$(featureCounts -v 2>&1) | sed -e "s/featureCounts v//g")
    END_VERSIONS
    """
}