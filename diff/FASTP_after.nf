```
// this process performs fastp trimming and filtering on sequencing reads
process FASTP {
    // tag the process with a unique identifier
    tag "$meta.id"
    // label the process as 'process_medium'
    label 'process_medium'

    // specify the conda environment for the process
    conda "${moduleDir}/environment.yml"
    // define the container to be used based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastp:0.23.4--h5f740d0_0' :
        'biocontainers/fastp:0.23.4--h5f740d0_0' }"

    // input section for the process
    input:
    // tuple containing metadata and read paths
    tuple val(meta), path(reads)
    // path for adapter fasta file
    path  adapter_fasta
    // boolean values for trim and save options
    val   discard_trimmed_pass
    val   save_trimmed_fail
    val   save_merged

    // output section for the process
    output:
    // output tuple for trimmed fastq files
    tuple val(meta), path('*.fastp.fastq.gz') , optional:true, emit: reads
    // output tuple for JSON file
    tuple val(meta), path('*.json')           , emit: json
    // output tuple for HTML report
    tuple val(meta), path('*.html')           , emit: html
    // output tuple for log file
    tuple val(meta), path('*.log')            , emit: log
    // output tuple for failed fastq files
    tuple val(meta), path('*.fail.fastq.gz')  , optional:true, emit: reads_fail
    // output tuple for merged fastq files
    tuple val(meta), path('*.merged.fastq.gz'), optional:true, emit: reads_merged
    // output for versions file
    path "versions.yml"                       , emit: versions

    // when clause to determine task execution
    when:
    task.ext.when == null || task.ext.when

    // script section for the main processing logic
    script:
    // initialize arguments and prefix for output files
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // define adapter list based on input
    def adapter_list = adapter_fasta ? "--adapter_fasta ${adapter_fasta}" : ""
    // define output for failed fastq files based on conditions
    def fail_fastq = save_trimmed_fail && meta.single_end ? "--failed_out ${prefix}.fail.fastq.gz" : save_trimmed_fail && !meta.single_end ? "--failed_out ${prefix}.paired.fail.fastq.gz --unpaired1 ${prefix}_1.fail.fastq.gz --unpaired2 ${prefix}_2.fail.fastq.gz" : ''
    // define output for trimmed fastq files
    def out_fq1 = discard_trimmed_pass ?: ( meta.single_end ? "--out1 ${prefix}.fastp.fastq.gz" : "--out1 ${prefix}_1.fastp.fastq.gz" )
    def out_fq2 = discard_trimmed_pass ?: "--out2 ${prefix}_2.fastp.fastq.gz"
    // Added soft-links to original fastqs for consistent naming in MultiQC
    // Use single ended for interleaved. Add --interleaved_in in config.
    // condition for handling interleaved input
    if ( task.ext.args?.contains('--interleaved_in') ) {
        """
        // create a symbolic link if the fastq file does not exist
        [ ! -f  ${prefix}.fastq.gz ] && ln -sf $reads ${prefix}.fastq.gz

        // run fastp with specified parameters
        fastp \\
            --stdout \\
            --in1 ${prefix}.fastq.gz \\
            --thread $task.cpus \\
            --json ${prefix}.fastp.json \\
            --html ${prefix}.fastp.html \\
            $adapter_list \\
            $fail_fastq \\
            $args \\
            2> >(tee ${prefix}.fastp.log >&2) \\
        | gzip -c > ${prefix}.fastp.fastq.gz

        // output the version of fastp to versions.yml
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
        END_VERSIONS
        """
    // condition for handling single-end data
    } else if (meta.single_end) {
        """
        // create a symbolic link if the fastq file does not exist
        [ ! -f  ${prefix}.fastq.gz ] && ln -sf $reads ${prefix}.fastq.gz

        // run fastp with specified parameters
        fastp \\
            --in1 ${prefix}.fastq.gz \\
            $out_fq1 \\
            --thread $task.cpus \\
            --json ${prefix}.fastp.json \\
            --html ${prefix}.fastp.html \\
            $adapter_list \\
            $fail_fastq \\
            $args \\
            2> >(tee ${prefix}.fastp.log >&2)

        // output the version of fastp to versions.yml
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
        END_VERSIONS
        """
    // condition for handling paired-end data
    } else {
        // define merging option if selected
        def merge_fastq = save_merged ? "-m --merged_out ${prefix}.merged.fastq.gz" : ''
        """
        // create symbolic links for paired-end fastq files
        [ ! -f  ${prefix}_1.fastq.gz ] && ln -sf ${reads[0]} ${prefix}_1.fastq.gz
        [ ! -f  ${prefix}_2.fastq.gz ] && ln -sf ${reads[1]} ${prefix}_2.fastq.gz
        // run fastp with specified parameters for paired-end data
        fastp \\
            --in1 ${prefix}_1.fastq.gz \\
            --in2 ${prefix}_2.fastq.gz \\
            $out_fq1 \\
            $out_fq2 \\
            --json ${prefix}.fastp.json \\
            --html ${prefix}.fastp.html \\
            $adapter_list \\
            $fail_fastq \\
            $merge_fastq \\
            --thread $task.cpus \\
            --detect_adapter_for_pe \\
            $args \\
            2> >(tee ${prefix}.fastp.log >&2)

        // output the version of fastp to versions.yml
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
        END_VERSIONS
        """
    }

    // stub section for handling temporary files
    stub:
    // initialize prefix for output files
    def prefix              = task.ext.prefix ?: "${meta.id}"
    // determine if the output is single based on input arguments
    def is_single_output    = task.ext.args?.contains('--interleaved_in') || meta.single_end
    // define commands to create empty fastq files if needed
    def touch_reads         = (discard_trimmed_pass) ? "" : (is_single_output) ? "echo '' | gzip > ${prefix}.fastp.fastq.gz" : "echo '' | gzip > ${prefix}_1.fastp.fastq.gz ; echo '' | gzip > ${prefix}_2.fastp.fastq.gz"
    def touch_merged        = (!is_single_output && save_merged) ? "echo '' | gzip >  ${prefix}.merged.fastq.gz" : ""
    def touch_fail_fastq    = (!save_trimmed_fail) ? "" : meta.single_end ? "echo '' | gzip > ${prefix}.fail.fastq.gz" : "echo '' | gzip > ${prefix}.paired.fail.fastq.gz ; echo '' | gzip > ${prefix}_1.fail.fastq.gz ; echo '' | gzip > ${prefix}_2.fail.fastq.gz"
    """
    // create necessary files for output
    $touch_reads
    $touch_fail_fastq
    $touch_merged
    touch "${prefix}.fastp.json"
    touch "${prefix}.fastp.html"
    touch "${prefix}.fastp.log"

    // output the version of fastp to versions.yml
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
    END_VERSIONS
    """
}
```