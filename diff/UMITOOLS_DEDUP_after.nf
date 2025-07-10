```
// this process performs deduplication using UMI-tools
process UMITOOLS_DEDUP {
    // tag the process with the unique meta ID
    tag "$meta.id"
    // label the process for identification
    label "process_medium"

    // specify the conda environment required for the process
    conda "${moduleDir}/environment.yml"
    // define the container to be used based on the workflow engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/umi_tools:1.1.5--py39hf95cd2a_0' :
        'biocontainers/umi_tools:1.1.5--py39hf95cd2a_0' }"

    // input section defining the expected inputs for the process
    input:
    // tuple containing metadata and paths to BAM and BAI files
    tuple val(meta), path(bam), path(bai)
    // additional variable for output statistics
    val get_output_stats

    // output section defining the results produced by the process
    output:
    // tuple containing metadata and path to the deduplicated BAM file
    tuple val(meta), path("${prefix}.bam")     , emit: bam
    // tuple for the log file generated during the process
    tuple val(meta), path("*.log")             , emit: log
    // optional output for edit distance statistics
    tuple val(meta), path("*edit_distance.tsv"), optional:true, emit: tsv_edit_distance
    // optional output for per-UMI statistics
    tuple val(meta), path("*per_umi.tsv")      , optional:true, emit: tsv_per_umi
    // optional output for per-position statistics
    tuple val(meta), path("*per_position.tsv") , optional:true, emit: tsv_umi_per_position
    // output for versions file detailing the tools used
    path  "versions.yml"                       , emit: versions

    // condition under which the task should run
    when:
    task.ext.when == null || task.ext.when

    // script section containing the main logic for the deduplication process
    script:
    // defining arguments and prefix for output files
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    // determine if input is paired or single-end
    def paired = meta.single_end ? "" : "--paired"
    // define statistics output option
    stats = get_output_stats ? "--output-stats ${prefix}" : ""
    // error checking for input and output name conflict
    if ("$bam" == "${prefix}.bam") error "Input and output names are the same, set prefix in module configuration to disambiguate!"

    // ensure a random seed is set for reproducibility
    if (!(args ==~ /.*--random-seed.*/)) {args += " --random-seed=100"}
    // command to execute UMI-tools deduplication
    """
    PYTHONHASHSEED=0 umi_tools \\
        dedup \\
        -I $bam \\
        -S ${prefix}.bam \\
        -L ${prefix}.log \\
        $stats \\
        $paired \\
        $args

    // output versions information to a YAML file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        umitools: \$( umi_tools --version | sed '/version:/!d; s/.*: //' )
    END_VERSIONS
    """

    // stub section for creating empty output files in case of a dry run
    stub:
    // define prefix for output files
    prefix = task.ext.prefix ?: "${meta.id}"
    // commands to touch (create) empty files for expected outputs
    """
    touch ${prefix}.bam
    touch ${prefix}.log
    touch ${prefix}_edit_distance.tsv
    touch ${prefix}_per_umi.tsv
    touch ${prefix}_per_position.tsv

    // output versions information to a YAML file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        umitools: \$( umi_tools --version | sed '/version:/!d; s/.*: //' )
    END_VERSIONS
    """
}
```