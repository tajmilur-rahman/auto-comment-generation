```
// this process calculates RSEM expression for RNA-Seq data
process RSEM_CALCULATEEXPRESSION {
    // tag for process identification
    tag "$meta.id"
    // label for the process
    label 'process_high'

    // specifying the conda environment to be used
    conda "${moduleDir}/environment.yml"
    // defining the container to be used based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-cf0123ef83b3c38c13e3b0696a3f285d3f20f15b:64aad4a4e144878400649e71f42105311be7ed87-0' :
        'biocontainers/mulled-v2-cf0123ef83b3c38c13e3b0696a3f285d3f20f15b:64aad4a4e144878400649e71f42105311be7ed87-0' }"

    // section for input parameters
    input:
    // input tuple containing metadata and path to reads
    tuple val(meta), path(reads)
    // input path for index
    path  index

    // section for output parameters
    output:
    // output tuple for gene counts results
    tuple val(meta), path("*.genes.results")   , emit: counts_gene
    // output tuple for transcript counts results
    tuple val(meta), path("*.isoforms.results"), emit: counts_transcript
    // output tuple for statistics results
    tuple val(meta), path("*.stat")            , emit: stat
    // output tuple for log files
    tuple val(meta), path("*.log")             , emit: logs
    // output path for versions
    path  "versions.yml"                       , emit: versions

    // optional output for STAR genome BAM file
    tuple val(meta), path("*.STAR.genome.bam")       , optional:true, emit: bam_star
    // optional output for genome BAM file
    tuple val(meta), path("${prefix}.genome.bam")    , optional:true, emit: bam_genome
    // optional output for transcript BAM file
    tuple val(meta), path("${prefix}.transcript.bam"), optional:true, emit: bam_transcript

    // condition determining when to execute the process
    when:
    task.ext.when == null || task.ext.when

    // script section containing the main logic
    script:
    // defining arguments and prefix for the command
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"

    // determining strandedness based on metadata
    def strandedness = ''
    if (meta.strandedness == 'forward') {
        strandedness = '--strandedness forward'
    } else if (meta.strandedness == 'reverse') {
        strandedness = '--strandedness reverse'
    }
    // setting paired-end option based on single-end metadata
    def paired_end = meta.single_end ? "" : "--paired-end"
    // command to execute RSEM
    """
    INDEX=`find -L ./ -name "*.grp" | sed 's/\\.grp\$//'`
    rsem-calculate-expression \\
        --num-threads $task.cpus \\
        --temporary-folder ./tmp/ \\
        $strandedness \\
        $paired_end \\
        $args \\
        $reads \\
        \$INDEX \\
        $prefix

    // creating versions.yml file with software versions
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rsem: \$(rsem-calculate-expression --version | sed -e "s/Current version: RSEM v//g")
        star: \$(STAR --version | sed -e "s/STAR_//g")
    END_VERSIONS
    """

    // stub section for testing or placeholder execution
    stub:
    // defining prefix for stub execution
    prefix = task.ext.prefix ?: "${meta.id}"
    // creating placeholder files for output
    """
    touch ${prefix}.genes.results
    touch ${prefix}.isoforms.results
    touch ${prefix}.stat
    touch ${prefix}.log
    touch ${prefix}.STAR.genome.bam
    touch ${prefix}.genome.bam
    touch ${prefix}.transcript.bam

    // creating versions.yml file with software versions in stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rsem: \$(rsem-calculate-expression --version | sed -e "s/Current version: RSEM v//g")
        star: \$(STAR --version | sed -e "s/STAR_//g")
    END_VERSIONS
    """
}
```