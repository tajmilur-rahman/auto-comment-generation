```
// this process handles RSEQC_TIN workflow for analyzing sequencing data
process RSEQC_TIN {
    // sets a tag for the process using the meta.id
    tag "$meta.id"
    // assigns a label to categorize the process
    label 'process_high'

    // specifies the conda environment to use for the process
    conda "${moduleDir}/environment.yml"
    // determines the container image based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/rseqc:5.0.3--py39hf95cd2a_0' :
        'biocontainers/rseqc:5.0.3--py39hf95cd2a_0' }"

    // input section defines the required input data for the process
    input:
    // tuple containing metadata, BAM file path, and BAI file path
    tuple val(meta), path(bam), path(bai)
    // path to the bed file
    path  bed

    // output section defines the generated output data from the process
    output:
    // tuple containing metadata and path for the text output file
    tuple val(meta), path("*.txt"), emit: txt
    // tuple containing metadata and path for the Excel output file
    tuple val(meta), path("*.xls"), emit: xls
    // path for versions.yml file, emitting versions
    path "versions.yml"           , emit: versions

    // conditional execution based on task.ext.when value
    when:
    task.ext.when == null || task.ext.when

    // script section contains the main code to execute during the process
    script:
    // retrieves additional arguments and sets a default prefix
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    // command to run the tin.py script with specified inputs
    tin.py \\
        -i $bam \\
        -r $bed \\
        $args

    // writes the versions of the rseqc tool to versions.yml
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rseqc: \$(tin.py --version | sed -e "s/tin.py //g")
    END_VERSIONS
    """

    // stub section provides a placeholder for execution without actual processing
    stub:
    // sets a default prefix for stub execution
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    // creates summary and Excel files for the BAM file
    touch ${bam.fileName}.summary.txt
    touch ${bam.fileName}.tin.xls

    // writes the versions of the rseqc tool to versions.yml in the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rseqc: \$(tin.py --version | sed -e "s/tin.py //g")
    END_VERSIONS
    """
}
```