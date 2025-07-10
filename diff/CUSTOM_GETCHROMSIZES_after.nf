```
// this process retrieves chromosome sizes using samtools
process CUSTOM_GETCHROMSIZES {
    // set the tag for the process
    tag "$fasta"
    // label the process for identification
    label 'process_single'

    // specify the conda environment to use
    conda "${moduleDir}/environment.yml"
    // determine the container image based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    // input section where metadata and fasta file path are defined
    input:
    tuple val(meta), path(fasta)

    // output section specifying the expected output files and their metadata
    output:
    tuple val(meta), path ("*.sizes"), emit: sizes
    tuple val(meta), path ("*.fai")  , emit: fai
    tuple val(meta), path ("*.gzi")  , emit: gzi, optional: true
    path  "versions.yml"             , emit: versions

    // condition to run the process based on task extension
    when:
    task.ext.when == null || task.ext.when

    // script section containing the commands to be executed
    script:
    def args = task.ext.args ?: ''
    """
    // run samtools to index the fasta file and generate sizes
    samtools faidx $fasta
    cut -f 1,2 ${fasta}.fai > ${fasta}.sizes

    // create a versions.yml file with the samtools version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        getchromsizes: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    // stub section for testing without actual processing
    stub:
    """
    // create empty files for the expected outputs
    touch ${fasta}.fai
    touch ${fasta}.sizes
    // conditionally create a gzi file if the fasta is gzipped
    if [[ "${fasta.extension}" == "gz" ]]; then
        touch ${fasta}.gzi
    fi

    // create a versions.yml file with the samtools version in the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        getchromsizes: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
```