```
// this process handles the gunzip operation for decompressing files
process GUNZIP {
    // assigning a tag to the process
    tag "$archive"
    // labeling the process for identification
    label 'process_single'

    // setting up conda environment using a specified YAML file
    conda "${moduleDir}/environment.yml"
    // selecting the container based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:22.04' :
        'nf-core/ubuntu:22.04' }"

    // defining the input parameters for the process
    input:
    tuple val(meta), path(archive)

    // defining the output parameters of the process
    output:
    tuple val(meta), path("$gunzip"), emit: gunzip
    path "versions.yml"             , emit: versions

    // defining when the process should run based on a condition
    when:
    task.ext.when == null || task.ext.when

    // script section containing the commands to execute
    script:
    // capturing additional arguments if provided
    def args        = task.ext.args ?: ''
    // extracting the file extension from the archive name
    def extension   = ( archive.toString() - '.gz' ).tokenize('.')[-1]
    // deriving the name from the archive by removing the extension
    def name        = archive.toString() - '.gz' - ".$extension"
    // setting a prefix for the output filename
    def prefix      = task.ext.prefix ?: name
    // constructing the output filename for the gunzipped file
    gunzip          = prefix + ".$extension"
    // using gzip command to decompress the archive
    """
    # Not calling gunzip itself because it creates files
    # with the original group ownership rather than the
    # default one for that user / the work directory
    gzip \\
        -cd \\
        $args \\
        $archive \\
        > $gunzip

    // writing the version information to a YAML file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gunzip: \$(echo \$(gunzip --version 2>&1) | sed 's/^.*(gzip) //; s/ Copyright.*\$//')
    END_VERSIONS
    """

    // stub section for testing purposes without actual execution
    stub:
    // capturing additional arguments if provided
    def args        = task.ext.args ?: ''
    // extracting the file extension from the archive name
    def extension   = ( archive.toString() - '.gz' ).tokenize('.')[-1]
    // deriving the name from the archive by removing the extension
    def name        = archive.toString() - '.gz' - ".$extension"
    // setting a prefix for the output filename
    def prefix      = task.ext.prefix ?: name
    // constructing the output filename for the stubbed gunzipped file
    gunzip          = prefix + ".$extension"
    // creating a placeholder for the gunzipped file
    """
    touch $gunzip
    // writing the version information to a YAML file for the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gunzip: \$(echo \$(gunzip --version 2>&1) | sed 's/^.*(gzip) //; s/ Copyright.*\$//')
    END_VERSIONS
    """
}
```