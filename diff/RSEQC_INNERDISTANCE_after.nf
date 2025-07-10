```
// this process calculates inner distance metrics for sequencing data
process RSEQC_INNERDISTANCE {
    // tag for identifying the process metadata
    tag "$meta.id"
    // label for the process
    label 'process_medium'

    // specify conda environment for the process
    conda "${moduleDir}/environment.yml"
    // specify container image based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/rseqc:5.0.3--py39hf95cd2a_0' :
        'biocontainers/rseqc:5.0.3--py39hf95cd2a_0' }"

    // input section defining the required input files
    input:
    tuple val(meta), path(bam) // input metadata and BAM file
    path  bed // input BED file

    // output section defining the expected output files
    output:
    tuple val(meta), path("*distance.txt"), optional:true, emit: distance // output distance file
    tuple val(meta), path("*freq.txt")    , optional:true, emit: freq // output frequency file
    tuple val(meta), path("*mean.txt")    , optional:true, emit: mean // output mean file
    tuple val(meta), path("*.pdf")        , optional:true, emit: pdf // output PDF file
    tuple val(meta), path("*.r")          , optional:true, emit: rscript // output R script file
    path  "versions.yml"                  , emit: versions // output versions file

    // condition under which the process will run
    when:
    task.ext.when == null || task.ext.when

    // script section containing the main processing commands
    script:
    def args = task.ext.args ?: '' // retrieve additional arguments or set to empty
    def prefix = task.ext.prefix ?: "${meta.id}" // determine prefix for output files
    if (!meta.single_end) { // check if the data is paired-end
        """
        inner_distance.py \\
            -i $bam \\ // input BAM file for the script
            -r $bed \\ // input BED file for the script
            -o $prefix \\ // output prefix for the results
            $args \\ // additional arguments for the script
            > stdout.txt // redirect standard output to a file
        head -n 2 stdout.txt > ${prefix}.inner_distance_mean.txt // extract mean from output

        cat <<-END_VERSIONS > versions.yml // create versions file
        "${task.process}":
            rseqc: \$(inner_distance.py --version | sed -e "s/inner_distance.py //g") // version command
        END_VERSIONS
        """
    } else {
        """
        cat <<-END_VERSIONS > versions.yml // create versions file for single-end data
        "${task.process}":
            rseqc: \$(inner_distance.py --version | sed -e "s/inner_distance.py //g") // version command
        END_VERSIONS
        """
    }

    // stub section for creating placeholder files if the process does not run
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}" // determine prefix for output files
    """
    touch ${prefix}.inner_distance.txt // create placeholder for distance output
    touch ${prefix}.inner_distance_freq.txt // create placeholder for frequency output
    touch ${prefix}.inner_distance_mean.txt // create placeholder for mean output
    touch ${prefix}.inner_distance_plot.pdf // create placeholder for plot output
    touch ${prefix}.inner_distance_plot.r // create placeholder for R script output

    cat <<-END_VERSIONS > versions.yml // create versions file
    "${task.process}":
        rseqc: \$(inner_distance.py --version | sed -e "s/inner_distance.py //g") // version command
    END_VERSIONS
    """
}
```