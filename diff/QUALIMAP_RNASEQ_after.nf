```
// this process runs the QUALIMAP tool for RNA-Seq analysis
process QUALIMAP_RNASEQ {
    
    // tag the process with a unique identifier
    tag "$meta.id"
    
    // label the process for categorization
    label 'process_medium'

    // specify the conda environment for the process
    conda "${moduleDir}/environment.yml"
    
    // define the container image to be used based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/qualimap:2.3--hdfd78af_0' :
        'biocontainers/qualimap:2.3--hdfd78af_0' }"

    // input section defining the required input tuples
    input:
    tuple val(meta), path(bam)
    tuple val(meta2), path(gtf)

    // output section defining the output tuples and files
    output:
    tuple val(meta), path("${prefix}"), emit: results
    path  "versions.yml"              , emit: versions

    // condition under which the process should run
    when:
    task.ext.when == null || task.ext.when

    // script section containing the main execution logic
    script:
    // initialize arguments and prefix for output
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"
    
    // determine if the input data is paired-end or single-end
    def paired_end = meta.single_end ? '' : '-pe'
    
    // calculate memory allocation for the process
    def memory = (task.memory.mega*0.8).intValue() + 'M'

    // set strandedness based on metadata
    def strandedness = 'non-strand-specific'
    if (meta.strandedness == 'forward') {
        strandedness = 'strand-specific-forward'
    } else if (meta.strandedness == 'reverse') {
        strandedness = 'strand-specific-reverse'
    }
    
    // command to run QUALIMAP with the specified parameters
    """
    unset DISPLAY
    mkdir -p tmp
    export _JAVA_OPTIONS=-Djava.io.tmpdir=./tmp
    qualimap \\
        --java-mem-size=$memory \\
        rnaseq \\
        $args \\
        -bam $bam \\
        -gtf $gtf \\
        -p $strandedness \\
        $paired_end \\
        -outdir $prefix

    // output the versions of the tools used to a YAML file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qualimap: \$(echo \$(qualimap 2>&1) | sed 's/^.*QualiMap v.//; s/Built.*\$//')
    END_VERSIONS
    """

    // stub section for creating output directory
    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    // create the output directory
    """
    mkdir ${prefix}

    // output the versions of the tools used to a YAML file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qualimap: \$(echo \$(qualimap 2>&1) | sed 's/^.*QualiMap v.//; s/Built.*\$//')
    END_VERSIONS
    """
}
```