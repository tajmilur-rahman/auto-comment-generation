```
// this process runs the DUPRADAR analysis
process DUPRADAR {
    // assigns a unique identifier for the process
    tag "$meta.id"
    // assigns a label for the process
    label 'process_long'

    // specifies the conda environment to use
    conda "${moduleDir}/environment.yml"
    // determines the container to be used based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-dupradar:1.32.0--r43hdfd78af_0' :
        'biocontainers/bioconductor-dupradar:1.32.0--r43hdfd78af_0' }"

    // input section defines the input files for the process
    input:
    // first input tuple consisting of metadata and a BAM file
    tuple val(meta), path(bam)
    // second input tuple consisting of metadata and a GTF file
    tuple val(meta2), path(gtf)

    // output section defines the output files from the process
    output:
    // output tuple for density plot, emitting scatter2d
    tuple val(meta), path("*_duprateExpDens.pdf")   , emit: scatter2d
    // output tuple for boxplot, emitting boxplot
    tuple val(meta), path("*_duprateExpBoxplot.pdf"), emit: boxplot
    // output tuple for expression histogram, emitting hist
    tuple val(meta), path("*_expressionHist.pdf")   , emit: hist
    // output tuple for duplication matrix, emitting dupmatrix
    tuple val(meta), path("*_dupMatrix.txt")        , emit: dupmatrix
    // output tuple for intercept slope data, emitting intercept_slope
    tuple val(meta), path("*_intercept_slope.txt")  , emit: intercept_slope
    // output tuple for multiQC results, emitting multiqc
    tuple val(meta), path("*_mqc.txt")              , emit: multiqc
    // output tuple for R session info log, emitting session_info
    tuple val(meta), path("*.R_sessionInfo.log")    , emit: session_info
    // output path for versions information, emitting versions
    path "versions.yml"                             , emit: versions

    // condition to determine when the task should run
    when:
    task.ext.when == null || task.ext.when

    // script section specifies the R script template to be executed
    script:
    template 'dupradar.r'

    // stub section contains commands to create output files and versioning information
    stub:
    """
    // create placeholder files for the various outputs
    touch ${meta.id}_duprateExpDens.pdf
    touch ${meta.id}_duprateExpBoxplot.pdf
    touch ${meta.id}_expressionHist.pdf
    touch ${meta.id}_dupMatrix.txt
    touch ${meta.id}_intercept_slope.txt
    touch ${meta.id}_dup_intercept_mqc.txt
    touch ${meta.id}_duprateExpDensCurve_mqc.txt
    touch ${meta.id}.R_sessionInfo.log

    // output the versions of the R package used
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioconductor-dupradar: \$(Rscript -e "library(dupRadar); cat(as.character(packageVersion('dupRadar')))")
    END_VERSIONS
    """
}
```