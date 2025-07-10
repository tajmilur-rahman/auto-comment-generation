```
// this process runs the GFFREAD tool to convert GFF files and generate outputs in different formats
process GFFREAD {
    // assigns a tag to the process based on metadata id
    tag "$meta.id"
    // sets a label for the process
    label 'process_low'

    // specifies the conda environment required for this process
    conda "${moduleDir}/environment.yml"
    // selects the container image to use based on the workflow settings
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gffread:0.12.7--hdcf5f25_4' :
        'biocontainers/gffread:0.12.7--hdcf5f25_4' }"

    // defines the inputs for the process
    input:
    // input tuple containing metadata and GFF file path
    tuple val(meta), path(gff)
    // input path for fasta file
    path fasta

    // defines the outputs for the process
    output:
    // output tuple for GTF file, optional
    tuple val(meta), path("*.gtf")  , emit: gtf             , optional: true
    // output tuple for GFF3 file, optional
    tuple val(meta), path("*.gff3") , emit: gffread_gff     , optional: true
    // output tuple for fasta file, optional
    tuple val(meta), path("*.fasta"), emit: gffread_fasta   , optional: true
    // output path for versions file
    path "versions.yml"             , emit: versions

    // condition for when to execute the process
    when:
    task.ext.when == null || task.ext.when

    // script section containing the commands to run
    script:
    // initializes arguments from task extensions or defaults to empty string
    def args        = task.ext.args             ?: ''
    // initializes prefix from task extensions or defaults to metadata id
    def prefix      = task.ext.prefix           ?: "${meta.id}"
    // determines the output file extension based on input arguments
    def extension   = args.contains("-T")       ? 'gtf' : ( ( ['-w', '-x', '-y' ].any { args.contains(it) } ) ? 'fasta' : 'gff3' )
    // sets fasta argument if fasta input is provided
    def fasta_arg   = fasta                     ? "-g $fasta" : ''
    // constructs the output file name based on prefix and extension
    def output_name = "${prefix}.${extension}"
    // determines the output command based on file type
    def output      = extension == "fasta"      ? "$output_name" : "-o $output_name"
    // sorts command line arguments
    def args_sorted = args.replaceAll(/(.*)(-[wxy])(.*)/) { all, pre, param, post -> "$pre $post $param" }.trim()
    // args_sorted  = Move '-w', '-x', and '-y' to the end of the args string as gffread expects the file name after these parameters
    // checks for name conflicts between input and output
    if ( "$output_name" in [ "$gff", "$fasta" ] ) error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    // command to execute gffread with the specified arguments
    """
    gffread \\
        $gff \\
        $fasta_arg \\
        $args_sorted \\
        $output

    // generates a versions file with the gffread version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gffread: \$(gffread --version 2>&1)
    END_VERSIONS
    """

    // stub section for testing purposes
    stub:
    // initializes arguments for the stub process
    def args        = task.ext.args             ?: ''
    // initializes prefix for the stub process
    def prefix      = task.ext.prefix           ?: "${meta.id}"
    // determines the output file extension for the stub
    def extension   = args.contains("-T")       ? 'gtf' : ( ( ['-w', '-x', '-y' ].any { args.contains(it) } ) ? 'fasta' : 'gff3' )
    // constructs the output file name for the stub
    def output_name = "${prefix}.${extension}"
    // checks for name conflicts in the stub process
    if ( "$output_name" in [ "$gff", "$fasta" ] ) error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    // command to create an empty file with the output name
    """
    touch $output_name

    // generates a versions file with the gffread version for the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gffread: \$(gffread --version 2>&1)
    END_VERSIONS
    """
}
```