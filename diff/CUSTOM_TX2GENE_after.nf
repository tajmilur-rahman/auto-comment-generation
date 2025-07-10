// this process transforms transcript data into gene-level quantification
process CUSTOM_TX2GENE {
    // assigns a tag based on the process metadata ID
    tag "$meta.id"
    // sets a label for the process
    label 'process_single'

    // specifies the conda environment to use
    conda "${moduleDir}/environment.yml"
    // defines the container image depending on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.10.4' :
        'biocontainers/python:3.10.4' }"

    // input section defining the expected input parameters for the process
    input:
    // a tuple consisting of metadata and the path to the GTF file
    tuple val(meta), path(gtf)
    // a tuple consisting of additional metadata and the path to quantification files
    tuple val(meta2), path ("quants/*")
    // additional single value inputs
    val quant_type
    val id
    val extra

    // output section defining what the process will produce
    output:
    // a tuple consisting of metadata and the path to the output file, with an emit label
    tuple val(meta), path("*tx2gene.tsv"), emit: tx2gene
    // path to versions file, with an emit label
    path "versions.yml"                  , emit: versions

    // condition under which the process will run
    when:
    task.ext.when == null || task.ext.when

    // script section that specifies the script template to be used
    script:
    template 'tx2gene.py'

    // stub section containing commands to be executed
    stub:
    """
    // creates an empty output file with the metadata ID
    touch ${meta.id}.tx2gene.tsv

    // writes the process and Python version information to a versions.yml file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}