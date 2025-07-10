```
// this process quantifies RNA-Seq data using the Salmon tool
process SALMON_QUANT {
    // assigns a tag for the process using meta information
    tag "$meta.id"
    // labels the process for identification
    label "process_medium"

    // specifies the conda environment to use
    conda "${moduleDir}/environment.yml"
    // determines the container image to use based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/salmon:1.10.3--h6dccd9a_2' :
        'biocontainers/salmon:1.10.3--h6dccd9a_2' }"

    // input section defining the required inputs for the process
    input:
    // inputs a tuple containing metadata and path for reads
    tuple val(meta), path(reads)
    // inputs paths for index, gtf, transcript fasta, and alignment mode
    path  index
    path  gtf
    path  transcript_fasta
    val   alignment_mode
    val   lib_type

    // output section defining the outputs of the process
    output:
    // outputs a tuple with metadata and results path
    tuple val(meta), path("${prefix}")              , emit: results
    // outputs a tuple with metadata and optional json info
    tuple val(meta), path("*info.json")             , emit: json_info, optional: true
    // outputs a tuple with metadata and optional library format counts
    tuple val(meta), path("*lib_format_counts.json"), emit: lib_format_counts, optional: true
    // outputs the versions file
    path  "versions.yml"                            , emit: versions

    // when condition to determine if the task should run
    when:
    task.ext.when == null || task.ext.when

    // script section containing the main logic for the process
    script:
    // initializes arguments and prefix for output
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"

    // sets up reference index based on input
    def reference   = "--index $index"
    // initializes read arrays for single-end and paired-end reads
    def reads1 = [], reads2 = []
    // processes reads based on whether they are single-end or paired-end
    meta.single_end ? [reads].flatten().each{reads1 << it} : reads.eachWithIndex{ v, ix -> ( ix & 1 ? reads2 : reads1) << v }
    // constructs input read arguments based on single-end or paired-end
    def input_reads = meta.single_end ? "-r ${reads1.join(" ")}" : "-1 ${reads1.join(" ")} -2 ${reads2.join(" ")}"
    // adjusts reference for alignment mode
    if (alignment_mode) {
        reference   = "-t $transcript_fasta"
        input_reads = "-a $reads"
    }

    // defines a list of acceptable strandedness options
    def strandedness_opts = [
        'A', 'U', 'SF', 'SR',
        'IS', 'IU' , 'ISF', 'ISR',
        'OS', 'OU' , 'OSF', 'OSR',
        'MS', 'MU' , 'MSF', 'MSR'
    ]
    // sets default strandedness
    def strandedness =  'A'
    // checks and sets strandedness based on library type
    if (lib_type) {
        if (strandedness_opts.contains(lib_type)) {
            strandedness = lib_type
        } else {
            log.info "[Salmon Quant] Invalid library type specified '--libType=${lib_type}', defaulting to auto-detection with '--libType=A'."
        }
    } else {
        strandedness = meta.single_end ? 'U' : 'IU'
        // adjusts strandedness based on meta information
        if (meta.strandedness == 'forward') {
            strandedness = meta.single_end ? 'SF' : 'ISF'
        } else if (meta.strandedness == 'reverse') {
            strandedness = meta.single_end ? 'SR' : 'ISR'
        }
    }
    // command to run the Salmon quantification tool
    """
    salmon quant \\
        --geneMap $gtf \\
        --threads $task.cpus \\
        --libType=$strandedness \\
        $reference \\
        $input_reads \\
        $args \\
        -o $prefix

    // conditional to check if meta_info.json exists and copy it
    if [ -f $prefix/aux_info/meta_info.json ]; then
        cp $prefix/aux_info/meta_info.json "${prefix}_meta_info.json"
    fi
    // conditional to check if lib_format_counts.json exists and copy it
    if [ -f $prefix/lib_format_counts.json ]; then
        cp $prefix/lib_format_counts.json "${prefix}_lib_format_counts.json"
    fi

    // creates versions.yml file with the version of Salmon used
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salmon: \$(echo \$(salmon --version) | sed -e "s/salmon //g")
    END_VERSIONS
    """

    // stub section to create output files and directories
    stub:
    // sets up prefix for output files
    prefix = task.ext.prefix ?: "${meta.id}"
    // commands to create necessary files and directories
    """
    mkdir ${prefix}
    touch ${prefix}_meta_info.json
    touch ${prefix}_lib_format_counts.json

    // creates versions.yml file with the version of Salmon used
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        salmon: \$(echo \$(salmon --version) | sed -e "s/salmon //g")
    END_VERSIONS
    """
}
```