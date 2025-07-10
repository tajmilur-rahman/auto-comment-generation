```groovy
// this process performs sorting of RNA sequences using SortMeRNA
process SORTMERNA {
    // tag to identify the process with a unique meta ID
    tag "$meta.id"
    // label for categorizing the process as high priority
    label 'process_high'

    // specify the conda environment for the process
    conda "${moduleDir}/environment.yml"
    // define the container image to be used for the process
    container 'nf-core/sortmerna:4.3.7--6502243397c065ba'

    // define input parameters for the process
    input:
    // tuple containing metadata and path to reads
    tuple val(meta), path(reads)
    // tuple containing metadata and path to fastas
    tuple val(meta2), path(fastas)
    // tuple containing metadata and path to index
    tuple val(meta3), path(index)

    // define output parameters for the process
    output:
    // tuple for non-rRNA reads output, optional
    tuple val(meta), path("*non_rRNA.fastq.gz"), emit: reads, optional: true
    // tuple for log file output, optional
    tuple val(meta), path("*.log")             , emit: log, optional: true
    // tuple for index output, optional
    tuple val(meta2), path("idx")              , emit: index, optional: true
    // path for versions output
    path  "versions.yml"                       , emit: versions

    // condition to determine when to run the task
    when:
    task.ext.when == null || task.ext.when

    // script section containing the main logic for the process
    script:
    // define arguments and prefix from task extensions
    def args          = task.ext.args  ?: ''
    def prefix        = task.ext.prefix ?: "${meta.id}"

    // flags to determine index handling
    def index_only    = args.contains('--index 1')? true : false
    def skip_index    = args.contains('--index 0')? true : false
    // check if reads are paired-end
    def paired_end    = reads instanceof List
    // initialize command variables
    def paired_cmd    = ''
    def reads_args    = ''
    def out2_cmd      = ''
    def mv_cmd        = ''
    def reads_input   = ''
    def refs_input    = ''

    // logic for handling non-indexed cases
    if (! index_only){
        // set arguments for read alignment
        reads_args = '--aligned rRNA_reads --fastx --other non_rRNA_reads'
        // construct input reads command based on paired-end status
        reads_input = paired_end ? reads.collect{"--reads $it"}.join(' ') : "--reads $reads"
        // determine the number of fastq files
        def n_fastq = paired_end ? reads.size() : 1
        // handle file movements based on number of fastq files
        if ( n_fastq == 1 ) {
            mv_cmd = """
            mv non_rRNA_reads.f*q.gz ${prefix}.non_rRNA.fastq.gz
            mv rRNA_reads.log ${prefix}.sortmerna.log
            """
        } else {
            mv_cmd = """
            mv non_rRNA_reads_fwd.f*q.gz ${prefix}_1.non_rRNA.fastq.gz
            mv non_rRNA_reads_rev.f*q.gz ${prefix}_2.non_rRNA.fastq.gz
            mv rRNA_reads.log ${prefix}.sortmerna.log
            """
            paired_cmd = "--paired_in"
            out2_cmd   = "--out2"
        }
    }
    // command to run SortMeRNA with all necessary parameters
    """
    sortmerna \\
        ${'--ref '+fastas.join(' --ref ')} \\
        $refs_input \\
        $reads_input \\
        --threads $task.cpus \\
        --workdir . \\
        $reads_args \\
        $paired_cmd \\
        $out2_cmd \\
        $args

    $mv_cmd

    // output versions of the tools used in the process
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sortmerna: \$(echo \$(sortmerna --version 2>&1) | sed 's/^.*SortMeRNA version //; s/ Build Date.*\$//')
    END_VERSIONS
    """

    // stub section to handle cases when the actual processing is not performed
    stub:
    // define arguments and prefix from task extensions
    def args          = task.ext.args  ?: ''
    def prefix        = task.ext.prefix ?: "${meta.id}"

    // flags to determine index handling
    def index_only    = args.contains('--index 1')? true : false
    // check if reads are paired-end
    def paired_end    = reads instanceof List
    // initialize command variables
    def paired_cmd    = ''
    def out2_cmd      = ''
    def mv_cmd        = ''
    def reads_input   = ''

    // logic for handling non-indexed cases in stub
    if (! index_only){
        // construct input reads command based on paired-end status
        reads_input = paired_end ? reads.collect{"--reads $it"}.join(' ') : "--reads $reads"
        // determine the number of fastq files
        def n_fastq = paired_end ? reads.size() : 1
        // handle file movements in stub
        if ( n_fastq == 1 ) {
            mv_cmd = "touch ${prefix}.non_rRNA.fastq.gz"
        } else {
            mv_cmd = """
            touch ${prefix}_1.non_rRNA.fastq.gz
            touch ${prefix}_2.non_rRNA.fastq.gz
            """
        }
    }
    // commands to create output files in stub
    """
    $mv_cmd
    mkdir -p idx
    touch ${prefix}.sortmerna.log

    // output versions of the tools used in the process in stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sortmerna: \$(echo \$(sortmerna --version 2>&1) | sed 's/^.*SortMeRNA version //; s/ Build Date.*\$//')
    END_VERSIONS
    """
}
```