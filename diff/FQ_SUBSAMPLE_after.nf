```
// this process performs subsampling on FASTQ files
process FQ_SUBSAMPLE {
    // tagging the process with a unique identifier
    tag "$meta.id"
    // labeling the process for easier identification
    label 'process_single'

    // specifying the conda environment to be used
    conda "${moduleDir}/environment.yml"
    // defining the container to run the process based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fq:0.12.0--h9ee0642_0':
        'biocontainers/fq:0.12.0--h9ee0642_0' }"

    // input section defining the input parameters for the process
    input:
    tuple val(meta), path(fastq)

    // output section defining what the process will produce
    output:
    tuple val(meta), path("*.fastq.gz"), emit: fastq
    path "versions.yml"                , emit: versions

    // condition to determine when the process should run
    when:
    task.ext.when == null || task.ext.when

    // script section containing the main logic of the process
    script:
    /* args requires:
        --probability <f64>: Probability read is kept, between 0 and 1. Mutually exclusive with record-count.
        --record-count <u64>: Number of records to keep. Mutually exclusive with probability
    */
    // retrieving the arguments passed to the task
    def args = task.ext.args ?: ''
    // checking if probability argument is provided
    def prob_exists = args =~ /-p|--probability/
    // checking if record-count argument is provided
    def nrec_exists = args =~ /-n|--record-count/
    // error handling if neither argument is provided
    if ( !(prob_exists || nrec_exists) ){
        error "FQ/SUBSAMPLE requires --probability (-p) or --record-count (-n) specified in task.ext.args!"
    }
    // setting a prefix for output files based on meta data or task extension
    def prefix = task.ext.prefix ?: "${meta.id}"
    // determining the number of FASTQ files provided as input
    def n_fastq = fastq instanceof List ? fastq.size() : 1
    // logging the number of FASTQ files found
    log.debug "FQ/SUBSAMPLE found ${n_fastq} FASTQ files"
    // defining output filenames based on the number of FASTQ files
    if ( n_fastq == 1 ){
        fastq1_output = "--r1-dst ${prefix}.fastq.gz"
        fastq2_output = ""
    } else if ( n_fastq == 2 ){
        fastq1_output = "--r1-dst ${prefix}_R1.fastq.gz"
        fastq2_output = "--r2-dst ${prefix}_R2.fastq.gz"
    } else {
        // error handling for unsupported number of FASTQ files
        error "FQ/SUBSAMPLE only accepts 1 or 2 FASTQ files!"
    }
    // executing the subsampling command with the specified arguments and outputs
    """
    fq subsample \\
        $args \\
        $fastq \\
        $fastq1_output \\
        $fastq2_output

    // creating a versions.yml file to log the version of the fq subsample tool
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fq: \$(echo \$(fq subsample --version | sed 's/fq-subsample //g'))
    END_VERSIONS
    """

    // stub section for generating placeholder outputs when the process is not run
    stub:
    // setting a prefix for the stub output
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    // creating empty gzipped FASTQ files as placeholders
    echo '' | gzip >  ${prefix}_R1.fastq.gz
    echo '' | gzip >  ${prefix}_R2.fastq.gz

    // creating a versions.yml file to log the version of the fq subsample tool for the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fq: \$(echo \$(fq subsample --version | sed 's/fq-subsample //g'))
    END_VERSIONS
    """
}
```