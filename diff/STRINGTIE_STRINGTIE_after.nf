```
// this process runs the STRINGTIE tool for transcript assembly and quantification
process STRINGTIE_STRINGTIE {
    // assigns a unique identifier to the process
    tag "$meta.id"
    // sets a label for the process
    label 'process_medium'

    // specifies the conda environment to use for the process
    conda "${moduleDir}/environment.yml"
    // determines the container image based on the container engine used
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/stringtie:2.2.3--h43eeafb_0' :
        'biocontainers/stringtie:2.2.3--h43eeafb_0' }"

    // this section defines the input parameters for the process
    input:
    // takes a tuple with metadata and a path to a BAM file
    tuple val(meta), path(bam)
    // takes a path to the annotation GTF file
    path  annotation_gtf

    // this section defines the output parameters for the process
    output:
    // emits a tuple with metadata and the path to the transcript GTF file
    tuple val(meta), path("*.transcripts.gtf"), emit: transcript_gtf
    // emits a tuple with metadata and the path to the abundance file
    tuple val(meta), path("*.abundance.txt")  , emit: abundance
    // optionally emits coverage GTF file
    tuple val(meta), path("*.coverage.gtf")   , optional: true, emit: coverage_gtf
    // optionally emits ballgown files
    tuple val(meta), path("*.ballgown")       , optional: true, emit: ballgown
    // emits a versions file
    path  "versions.yml"                      , emit: versions

    // condition to control when the process should be executed
    when:
    task.ext.when == null || task.ext.when

    // this section contains the script to execute the STRINGTIE command
    script:
    // initializes command-line arguments and parameters
    def args      = task.ext.args ?: ''
    // sets the prefix for output files based on metadata
    def prefix    = task.ext.prefix ?: "${meta.id}"
    // prepares the reference annotation option
    def reference = annotation_gtf ? "-G $annotation_gtf" : ""
    // prepares the ballgown option if annotation GTF is provided
    def ballgown  = annotation_gtf ? "-b ${prefix}.ballgown" : ""
    // prepares the coverage option if annotation GTF is provided
    def coverage  = annotation_gtf ? "-C ${prefix}.coverage.gtf" : ""

    // initializes strandedness option based on metadata
    def strandedness = ''
    if (meta.strandedness == 'forward') {
        strandedness = '--fr'
    } else if (meta.strandedness == 'reverse') {
        strandedness = '--rf'
    }
    // constructs the STRINGTIE command with all parameters and arguments
    """
    stringtie \\
        $bam \\
        $strandedness \\
        $reference \\
        -o ${prefix}.transcripts.gtf \\
        -A ${prefix}.gene.abundance.txt \\
        $coverage \\
        $ballgown \\
        -p $task.cpus \\
        $args

    // writes the version information of the STRINGTIE tool to a YAML file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stringtie: \$(stringtie --version 2>&1)
    END_VERSIONS
    """

    // this section defines a stub for the process, used for testing
    stub:
    // initializes the prefix for output files
    def prefix = task.ext.prefix ?: "${meta.id}"
    // creates empty files for expected output
    """
    touch ${prefix}.transcripts.gtf
    touch ${prefix}.gene.abundance.txt
    touch ${prefix}.coverage.gtf
    touch ${prefix}.ballgown

    // writes the version information of the STRINGTIE tool to a YAML file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stringtie: \$(stringtie --version 2>&1)
    END_VERSIONS
    """
}
```