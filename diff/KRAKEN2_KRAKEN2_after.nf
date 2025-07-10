```
// this process runs the KRAKEN2 tool for genomic classification
process KRAKEN2_KRAKEN2 {
    // tag for process identification
    tag "$meta.id"
    // label for categorizing the process
    label 'process_high'

    // specify conda environment for the process
    conda "${moduleDir}/environment.yml"
    // define the container to run the process with appropriate conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-8706a1dd73c6cc426e12dd4dd33a5e917b3989ae:c8cbdc8ff4101e6745f8ede6eb5261ef98bdaff4-0' :
        'biocontainers/mulled-v2-8706a1dd73c6cc426e12dd4dd33a5e917b3989ae:c8cbdc8ff4101e6745f8ede6eb5261ef98bdaff4-0' }"

    // define the input parameters for the process
    input:
    tuple val(meta), path(reads) // metadata and path to reads
    path  db // path to the database
    val save_output_fastqs // flag to save output fastq files
    val save_reads_assignment // flag to save reads assignment

    // define the output parameters for the process
    output:
    tuple val(meta), path('*.classified{.,_}*')     , optional:true, emit: classified_reads_fastq // classified reads output
    tuple val(meta), path('*.unclassified{.,_}*')   , optional:true, emit: unclassified_reads_fastq // unclassified reads output
    tuple val(meta), path('*classifiedreads.txt')   , optional:true, emit: classified_reads_assignment // classified reads assignment output
    tuple val(meta), path('*report.txt')                           , emit: report // report output
    path "versions.yml"                                            , emit: versions // versions file output

    // conditional execution based on the task's external when property
    when:
    task.ext.when == null || task.ext.when

    // main script to execute KRAKEN2
    script:
    def args = task.ext.args ?: '' // retrieve additional arguments
    def prefix = task.ext.prefix ?: "${meta.id}" // set prefix for output files
    def paired       = meta.single_end ? "" : "--paired" // determine if reads are paired
    def classified   = meta.single_end ? "${prefix}.classified.fastq"   : "${prefix}.classified#.fastq" // define classified output file name
    def unclassified = meta.single_end ? "${prefix}.unclassified.fastq" : "${prefix}.unclassified#.fastq" // define unclassified output file name
    def classified_option = save_output_fastqs ? "--classified-out ${classified}" : "" // option for classified output
    def unclassified_option = save_output_fastqs ? "--unclassified-out ${unclassified}" : "" // option for unclassified output
    def readclassification_option = save_reads_assignment ? "--output ${prefix}.kraken2.classifiedreads.txt" : "--output /dev/null" // option for reads assignment output
    def compress_reads_command = save_output_fastqs ? "pigz -p $task.cpus *.fastq" : "" // command to compress reads if required

    // command to run KRAKEN2 with all defined options
    """
    kraken2 \\
        --db $db \\
        --threads $task.cpus \\
        --report ${prefix}.kraken2.report.txt \\
        --gzip-compressed \\
        $unclassified_option \\
        $classified_option \\
        $readclassification_option \\
        $paired \\
        $args \\
        $reads

    $compress_reads_command

    // write versions of the tools used to versions.yml
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$(echo \$(kraken2 --version 2>&1) | sed 's/^.*Kraken version //; s/ .*\$//') // retrieve kraken2 version
        pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' ) // retrieve pigz version
    END_VERSIONS
    """

    // stub section for testing or placeholder functionality
    stub:
    def args = task.ext.args ?: '' // retrieve additional arguments
    def prefix = task.ext.prefix ?: "${meta.id}" // set prefix for output files
    def paired       = meta.single_end ? "" : "--paired" // determine if reads are paired
    def classified   = meta.single_end ? "${prefix}.classified.fastq.gz"   : "${prefix}.classified_1.fastq.gz ${prefix}.classified_2.fastq.gz" // define classified output file name
    def unclassified = meta.single_end ? "${prefix}.unclassified.fastq.gz" : "${prefix}.unclassified_1.fastq.gz ${prefix}.unclassified_2.fastq.gz" // define unclassified output file name
    def readclassification_option = save_reads_assignment ? "--output ${prefix}.kraken2.classifiedreads.txt" : "--output /dev/null" // option for reads assignment output
    def compress_reads_command = save_output_fastqs ? "pigz -p $task.cpus *.fastq" : "" // command to compress reads if required

    // commands to create placeholder files for stub execution
    """
    touch ${prefix}.kraken2.report.txt // create report file
    if [ "$save_output_fastqs" == "true" ]; then
        touch $classified // create classified output file
        touch $unclassified // create unclassified output file
    fi
    if [ "$save_reads_assignment" == "true" ]; then
        touch ${prefix}.kraken2.classifiedreads.txt // create reads assignment output file
    fi

    // write versions of the tools used to versions.yml
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$(echo \$(kraken2 --version 2>&1) | sed 's/^.*Kraken version //; s/ .*\$//') // retrieve kraken2 version
        pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' ) // retrieve pigz version
    END_VERSIONS
    """

}
```