```
// this process manages the conversion of FASTA files to GTF format
process CUSTOM_CATADDITIONALFASTA {
    // assigns a tag based on the meta.id
    tag "$meta.id"

    // specifies the environment using a conda environment file
    conda "${moduleDir}/environment.yml"
    // determines the container image based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.12' :
        'biocontainers/python:3.12' }"

    // defines the input variables for the process
    input:
    // receives a tuple of metadata and paths for fasta and gtf files
    tuple val(meta), path(fasta), path(gtf)
    // receives another tuple of metadata and a path for additional fasta
    tuple val(meta2), path(add_fasta)
    // receives a single value for biotype
    val  biotype

    // defines the output variables for the process
    output:
    // emits a tuple of metadata and paths for fasta files
    tuple val(meta), path("*/*.fasta") , emit: fasta
    // emits a tuple of metadata and paths for gtf files
    tuple val(meta), path("*/*.gtf")   , emit: gtf
    // emits a path for versions.yml
    path "versions.yml"                , emit: versions

    // specifies the condition under which the process will run
    when:
    task.ext.when == null || task.ext.when

    // specifies the script to be executed as part of the process
    script:
    // uses a template python script for the conversion process
    template 'fasta2gtf.py'

    // defines a stub for temporary code execution
    stub:
    // sets the prefix variable for output files based on metadata or defaults to meta.id
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    // creates an output directory
    mkdir out
    // creates a placeholder fasta file
    touch out/genome_transcriptome.fasta
    // creates a placeholder gtf file
    touch out/genome_transcriptome.gtf

    // writes the python version used in the process to versions.yml
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | grep -v "Python ")
    END_VERSIONS
    """
}
```