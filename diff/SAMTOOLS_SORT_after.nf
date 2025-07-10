```
// this process sorts BAM files using Samtools
process SAMTOOLS_SORT {
    // tag for identification of the process
    tag "$meta.id"
    // label for the process type
    label 'process_medium'

    // specifies the conda environment for the process
    conda "${moduleDir}/environment.yml"
    // selects the appropriate container image based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    // input section defining the expected input files
    input:
    // tuple containing metadata and BAM file path
    tuple val(meta) , path(bam)
    // tuple containing metadata and FASTA file path
    tuple val(meta2), path(fasta)

    // output section defining the expected output files
    output:
    // tuple for BAM file output, optional
    tuple val(meta), path("*.bam"),  emit: bam,  optional: true
    // tuple for CRAM file output, optional
    tuple val(meta), path("*.cram"), emit: cram, optional: true
    // tuple for CRAI file output, optional
    tuple val(meta), path("*.crai"), emit: crai, optional: true
    // tuple for CSI file output, optional
    tuple val(meta), path("*.csi"),  emit: csi,  optional: true
    // path for versions output, emits version information
    path  "versions.yml",            emit: versions

    // conditional execution based on task.ext.when value
    when:
    task.ext.when == null || task.ext.when

    // script section containing the commands to be executed
    script:
    // retrieves arguments and sets default prefix and extension
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def extension = args.contains("--output-fmt sam") ? "sam" :
                    args.contains("--output-fmt cram") ? "cram" :
                    "bam"
    // checks if the input and output names are the same
    def reference = fasta ? "--reference ${fasta}" : ""
    if ("$bam" == "${prefix}.bam") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"

    // commands for sorting BAM files using Samtools
    """
    samtools cat \\
        ${bam} \\
    | \\
    samtools sort \\
        $args \\
        -T ${prefix} \\
        --threads $task.cpus \\
        ${reference} \\
        -o ${prefix}.${extension} \\
        -

    // writing the versions used into a YAML file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    // stub section defines a placeholder for testing or dry run
    stub:
    // retrieves arguments and sets default prefix and extension
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def extension = args.contains("--output-fmt sam") ? "sam" :
                    args.contains("--output-fmt cram") ? "cram" :
                    "bam"
    // creates a placeholder file for the expected output
    """
    touch ${prefix}.${extension}
    // conditional creation of index files based on the output format
    if [ "${extension}" == "bam" ];
    then
        touch ${prefix}.${extension}.csi
    elif [ "${extension}" == "cram" ];
    then
        touch ${prefix}.${extension}.crai
    fi

    // writing the versions used into a YAML file for the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
```