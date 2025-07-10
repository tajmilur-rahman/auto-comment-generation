```
// this process handles the UMICollapse workflow
process UMICOLLAPSE {
    
    // tagging the process with metadata ID
    tag "$meta.id"
    // labeling the process for high priority
    label "process_high"
    // labeling the process for high memory usage
    label "process_high_memory"

    // specifying the conda environment for dependencies
    conda "${moduleDir}/environment.yml"
    // setting up the container image based on the workflow engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/umicollapse:1.1.0--hdfd78af_0' :
        'biocontainers/umicollapse:1.1.0--hdfd78af_0' }"

    // input section defining the expected inputs for the process
    input:
    // tuple containing metadata and input file paths
    tuple val(meta), path(input), path(bai)
    // additional input variable for mode
    val(mode)

    // output section defining the expected outputs of the process
    output:
    // tuple for BAM file output, which is optional
    tuple val(meta), path("*.bam"),                   emit: bam,        optional: true
    // tuple for deduplicated FASTQ file output, which is optional
    tuple val(meta), path("*dedup*fastq.gz"),         emit: fastq,      optional: true
    // tuple for log file output
    tuple val(meta), path("*_UMICollapse.log"),       emit: log
    // path for version information output
    path  "versions.yml" ,                            emit: versions

    // condition to execute the task based on external parameters
    when:
    task.ext.when == null || task.ext.when

    // script section containing the main logic for execution
    script:
    // retrieving arguments from task extension or setting to empty string
    def args   = task.ext.args ?: ''
    // setting prefix for output file names
    def prefix = task.ext.prefix ?: "${meta.id}"
    // defining the version of the UMICollapse tool
    def VERSION = '1.1.0-0' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    // calculating memory allocation for heap and stack sizes
    def max_heap_size_mega = (task.memory.toMega() * 0.9).intValue()
    def max_stack_size_mega = 999 //most java jdks will not allow Xss > 1GB, so fixing this to the allowed max
    // validating the mode input
    if ( mode !in [ 'fastq', 'bam' ] ) {
        error "Mode must be one of 'fastq' or 'bam'."
    }
    // determining the file extension based on mode
    extension = mode.contains("fastq") ? "fastq.gz" : "bam"
    """
    # getting the path to the UMICollapse jar file
    # using `which` to find the directory of the umicollapse tool
    UMICOLLAPSE_JAR=\$(dirname \$(which umicollapse))/../share/umicollapse-${VERSION}/umicollapse.jar
    // executing the Java command with specified memory settings and input/output parameters
    java \\
        -Xmx${max_heap_size_mega}M \\
        -Xss${max_stack_size_mega}M \\
        -jar \$UMICOLLAPSE_JAR \\
        $mode \\
        -i ${input} \\
        -o ${prefix}.${extension} \\
        $args | tee ${prefix}_UMICollapse.log

    // writing version information to the versions.yml file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        umicollapse: $VERSION
    END_VERSIONS
    """

    // stub section for handling cases where the main process can't run
    stub:
    // setting prefix for output file names
    def prefix = task.ext.prefix ?: "${meta.id}"
    // defining a fallback version for the UMICollapse tool
    def VERSION = '1.0.0-1'
    // validating the mode input
    if ( mode !in [ 'fastq', 'bam' ] ) {
        error "Mode must be one of 'fastq' or 'bam'."
    }
    // determining the file extension based on mode
    extension = mode.contains("fastq") ? "fastq.gz" : "bam"
    """
    // creating dummy output files for the stub
    touch ${prefix}.dedup.${extension}
    touch ${prefix}_UMICollapse.log
    // writing version information to the versions.yml file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        umicollapse: $VERSION
    END_VERSIONS
    """
}
```