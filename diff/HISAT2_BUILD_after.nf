```groovy
// this process builds a HISAT2 index from provided genomic data
process HISAT2_BUILD {
    // tags the process with the fasta file name
    tag "$fasta"
    // assigns a high priority label for process scheduling
    label 'process_high'
    // assigns a high memory label for process scheduling
    label 'process_high_memory'

    // specifies the conda environment for the process
    conda "${moduleDir}/environment.yml"
    // selects the appropriate container based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hisat2:2.2.1--h1b792b2_3' :
        'biocontainers/hisat2:2.2.1--h1b792b2_3' }"

    input:
    // accepts metadata and path to fasta file
    tuple val(meta), path(fasta)
    // accepts metadata and path to gtf file
    tuple val(meta2), path(gtf)
    // accepts metadata and path to splice sites
    tuple val(meta3), path(splicesites)

    output:
    // emits metadata and path to the HISAT2 index
    tuple val(meta), path("hisat2") , emit: index
    // emits a versions file for tracking software versions
    path "versions.yml"             , emit: versions

    when:
    // condition to determine when the task should run
    task.ext.when == null || task.ext.when

    script:
    // initializes arguments and available memory variables
    def args = task.ext.args ?: ''
    def avail_mem = 0
    // logs information about available memory if not specified
    if (!task.memory) {
        log.info "[HISAT2 index build] Available memory not known - defaulting to 0. Specify process memory requirements to change this."
    } else {
        // logs the available memory
        log.info "[HISAT2 index build] Available memory: ${task.memory}"
        avail_mem = task.memory.toGiga()
    }

    // initializes variables for splice sites and exons
    def ss = ''
    def exon = ''
    def extract_exons = ''
    // determines the required memory for HISAT2 build
    def hisat2_build_memory = params.hisat2_build_memory ? (params.hisat2_build_memory as nextflow.util.MemoryUnit).toGiga() : 0
    // checks if enough memory is available to use splice sites and exons
    if (avail_mem >= hisat2_build_memory) {
        log.info "[HISAT2 index build] At least ${hisat2_build_memory} GB available, so using splice sites and exons to build HISAT2 index"
        // prepares command to extract exons if gtf is provided
        extract_exons = gtf ? "hisat2_extract_exons.py $gtf > ${gtf.baseName}.exons.txt" : ""
        // prepares splice sites argument if provided
        ss = splicesites ? "--ss $splicesites" : ""
        // prepares exons argument if gtf is provided
        exon = gtf ? "--exon ${gtf.baseName}.exons.txt" : ""
    } else {
        // logs if not enough memory is available
        log.info "[HISAT2 index build] Less than ${hisat2_build_memory} GB available, so NOT using splice sites and exons to build HISAT2 index."
        log.info "[HISAT2 index build] Use --hisat2_build_memory [small number] to skip this check."
    }
    // shell commands to create directory and build HISAT2 index
    """
    mkdir hisat2
    $extract_exons
    hisat2-build \\
        -p $task.cpus \\
        $ss \\
        $exon \\
        $args \\
        $fasta \\
        hisat2/${fasta.baseName}

    // creates a versions file capturing the HISAT2 version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hisat2: \$(hisat2 --version | grep -o 'version [^ ]*' | cut -d ' ' -f 2)
    END_VERSIONS
    """

    // stub for the process that will be run if the main script fails
    stub:
    """
    mkdir hisat2

    // creates a versions file capturing the HISAT2 version in the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hisat2: \$(hisat2 --version | grep -o 'version [^ ]*' | cut -d ' ' -f 2)
    END_VERSIONS
    """
}
```