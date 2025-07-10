```
// this process performs quantification using Kallisto
process KALLISTO_QUANT {
    // tag the process with metadata ID
    tag "$meta.id"
    // label the process for high priority
    label 'process_high'

    // specify the conda environment for dependencies
    conda "${moduleDir}/environment.yml"
    // define the container image to be used based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kallisto:0.51.1--heb0cbe2_0':
        'biocontainers/kallisto:0.51.1--heb0cbe2_0' }"

    // input section defines required input parameters
    input:
    // input tuple with metadata and reads file path
    tuple val(meta), path(reads)
    // input tuple with metadata and index path
    tuple val(meta2), path(index)
    // input path for GTF file
    path gtf
    // input path for chromosomes file
    path chromosomes
    // input for fragment length value
    val fragment_length
    // input for fragment length standard deviation value
    val fragment_length_sd

    // output section defines the results produced by the process
    output:
    // output tuple with metadata and results path
    tuple val(meta), path("${prefix}")        , emit: results
    // output tuple for JSON info
    tuple val(meta), path("*.run_info.json")  , emit: json_info
    // output tuple for log files
    tuple val(meta), path("*.log")            , emit: log
    // output path for versions.yml file
    path "versions.yml"                       , emit: versions

    // condition to determine when to execute the task
    when:
    task.ext.when == null || task.ext.when

    // script section contains the execution commands
    script:
    // retrieve task arguments or set to empty string
    def args = task.ext.args ?: ''
    // set prefix for output directory
    prefix = task.ext.prefix ?: "${meta.id}"
    // prepare GTF input command if provided
    def gtf_input = gtf ? "--gtf ${gtf}" : ''
    // prepare chromosomes input command if provided
    def chromosomes_input = chromosomes ? "--chromosomes ${chromosomes}" : ''

    // initialize single-end parameters as empty
    def single_end_params = ''
    // check for single-end data and validate parameters
    if (meta.single_end) {
        if (!(fragment_length =~ /^\d+$/)) {
            error "fragment_length must be set and numeric for single-end data"
        }
        if (!(fragment_length_sd =~ /^\d+$/)) {
            error "fragment_length_sd must be set and numeric for single-end data"
        }
        // set parameters for single-end quantification
        single_end_params = "--single --fragment-length=${fragment_length} --sd=${fragment_length_sd}"
    }

    // initialize strandedness variable
    def strandedness = ''
    // determine strandedness based on metadata
    if (!args.contains('--fr-stranded') && !args.contains('--rf-stranded')) {
        strandedness =  (meta.strandedness == 'forward') ? '--fr-stranded' :
                        (meta.strandedness == 'reverse') ? '--rf-stranded' : ''
    }

    // commands to execute Kallisto quantification
    """
    mkdir -p $prefix && kallisto quant \\
            --threads ${task.cpus} \\
            --index ${index} \\
            ${gtf_input} \\
            ${chromosomes_input} \\
            ${single_end_params} \\
            ${strandedness} \\
            ${args} \\
            -o $prefix \\
            ${reads} 2> >(tee -a ${prefix}/kallisto_quant.log >&2)

    // copy log file to the output prefix
    cp ${prefix}/kallisto_quant.log ${prefix}.log
    // copy run info JSON file to the output prefix
    cp ${prefix}/run_info.json ${prefix}.run_info.json

    // create versions.yml with Kallisto version information
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kallisto: \$(echo \$(kallisto version) | sed "s/kallisto, version //g" )
    END_VERSIONS
    """

    // stub section for providing a minimal implementation
    stub:
    // set prefix for output directory
    prefix = task.ext.prefix ?: "${meta.id}"

    // commands to create output directory and files for stub
    """
    mkdir -p $prefix
    // create a log file for the stub
    touch ${prefix}.log
    // create a run info JSON file for the stub
    touch ${prefix}.run_info.json

    // create versions.yml with Kallisto version information
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kallisto: \$(echo \$(kallisto version) | sed "s/kallisto, version //g" )
    END_VERSIONS
    """
}
```