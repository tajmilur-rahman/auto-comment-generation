// this process summarizes the experiment using the SummarizedExperiment package
process SUMMARIZEDEXPERIMENT_SUMMARIZEDEXPERIMENT {
    // assign a tag to the process based on metadata id
    tag "$meta.id"
    // label the process as 'process_medium'
    label 'process_medium'

    // specify the conda environment to use for the process
    conda "${moduleDir}/environment.yml"
    // define the container to use based on the workflow container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-summarizedexperiment:1.32.0--r43hdfd78af_0' :
        'biocontainers/bioconductor-summarizedexperiment:1.32.0--r43hdfd78af_0' }"

    // input section where metadata and file paths are defined
    input:
    // input tuple containing metadata and path to matrix files
    tuple val(meta), path(matrix_files)
    // input tuple containing metadata and path to row data
    tuple val(meta2), path(rowdata)
    // input tuple containing metadata and path to column data
    tuple val(meta3), path(coldata)

    // output section where output files are specified
    output:
    // output tuple for RDS file, emitting with rds label
    tuple val(meta), path("*.rds")              , emit: rds
    // output tuple for log file, emitting with log label
    tuple val(meta), path("*.R_sessionInfo.log"), emit: log
    // output path for versions.yml file, emitting versions
    path "versions.yml"                         , emit: versions

    // condition to determine when the task should run
    when:
    task.ext.when == null || task.ext.when

    // script section specifying the template to use
    script:
    // use the 'summarizedexperiment.r' template for the script
    template 'summarizedexperiment.r'

    // stub section containing commands to execute
    stub:
    """
    // create an empty RDS file for the summarized experiment
    touch ${meta.id}.SummarizedExperiment.rds
    // create an empty log file for R session info
    touch ${meta.id}.R_sessionInfo.log

    // write the versions of the packages used to versions.yml
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioconductor-summarizedexperiment: \$(Rscript -e "library(SummarizedExperiment); cat(as.character(packageVersion('SummarizedExperiment')))")
    END_VERSIONS
    """
}