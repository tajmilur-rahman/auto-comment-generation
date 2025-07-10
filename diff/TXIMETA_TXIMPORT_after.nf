```
// this process imports transcript quantification data using the tximeta package
process TXIMETA_TXIMPORT {
    // label for the process
    label "process_medium"

    // specifies the conda environment to use
    conda "${moduleDir}/environment.yml"
    // selects the container image based on workflow conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-tximeta%3A1.20.1--r43hdfd78af_0' :
        'biocontainers/bioconductor-tximeta:1.20.1--r43hdfd78af_0' }"

    // input section defining the input data tuples
    input:
    // tuple containing meta information and a path to quantification files
    tuple val(meta), path("quants/*")
    // tuple containing additional meta information and a path to tx2gene file
    tuple val(meta2), path(tx2gene)
    // variable to define the type of quantification
    val quant_type

    // output section defining the expected output data tuples
    output:
    // output tuple for gene TPM values
    tuple val(meta), path("*gene_tpm.tsv")                 , emit: tpm_gene
    // output tuple for gene count values
    tuple val(meta), path("*gene_counts.tsv")              , emit: counts_gene
    // output tuple for length-scaled gene counts
    tuple val(meta), path("*gene_counts_length_scaled.tsv"), emit: counts_gene_length_scaled
    // output tuple for scaled gene counts
    tuple val(meta), path("*gene_counts_scaled.tsv")       , emit: counts_gene_scaled
    // output tuple for gene lengths
    tuple val(meta), path("*gene_lengths.tsv")             , emit: lengths_gene
    // output tuple for transcript TPM values
    tuple val(meta), path("*transcript_tpm.tsv")           , emit: tpm_transcript
    // output tuple for transcript count values
    tuple val(meta), path("*transcript_counts.tsv")        , emit: counts_transcript
    // output tuple for transcript lengths
    tuple val(meta), path("*transcript_lengths.tsv")       , emit: lengths_transcript
    // output path for versions file
    path "versions.yml"                                    , emit: versions

    // condition under which the task will run
    when:
    task.ext.when == null || task.ext.when

    // script section specifying the template to use for execution
    script:
    template 'tximport.r'

    // stub section for creating output files and versions documentation
    stub:
    """
    // create placeholder files for gene and transcript outputs
    touch ${meta.id}.gene_tpm.tsv
    touch ${meta.id}.gene_counts.tsv
    touch ${meta.id}.gene_counts_length_scaled.tsv
    touch ${meta.id}.gene_counts_scaled.tsv
    touch ${meta.id}.gene_lengths.tsv
    touch ${meta.id}.transcript_tpm.tsv
    touch ${meta.id}.transcript_counts.tsv
    touch ${meta.id}.transcript_lengths.tsv

    // generate versions file with package version information
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioconductor-tximeta: \$(Rscript -e "library(tximeta); cat(as.character(packageVersion('tximeta')))")
    END_VERSIONS
    """
}
```