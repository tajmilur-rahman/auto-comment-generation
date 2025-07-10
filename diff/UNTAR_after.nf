```
// this process handles the extraction of tar archives
process UNTAR {
    // assigns a tag to the process using the archive variable
    tag "$archive"
    // labels the process as 'process_single'
    label 'process_single'

    // specifies the conda environment to be used
    conda "${moduleDir}/environment.yml"
    // sets the container based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:22.04' :
        'nf-core/ubuntu:22.04' }"

    // defines the input for the process, specifying the metadata and archive path
    input:
    tuple val(meta), path(archive)

    // defines the output of the process, including metadata and extracted paths
    output:
    tuple val(meta), path("$prefix"), emit: untar
    path "versions.yml"             , emit: versions

    // condition to determine when the process should run
    when:
    task.ext.when == null || task.ext.when

    // script section that contains the extraction logic
    script:
    // initializes arguments and prefix variables for extraction
    def args  = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    prefix    = task.ext.prefix ?: ( meta.id ? "${meta.id}" : archive.baseName.toString().replaceFirst(/\.tar$/, ""))

    // creates the output directory with the determined prefix
    """
    mkdir $prefix

    // checks if the top level of the tar contents is a single directory
    // if true, applies --strip-components to the extraction
    if [[ \$(tar -taf ${archive} | grep -o -P "^.*?\\/" | uniq | wc -l) -eq 1 ]]; then
        tar \\
            -C $prefix --strip-components 1 \\
            -xavf \\
            $args \\
            $archive \\
            $args2
    else
        // if false, extracts all files without stripping components
        tar \\
            -C $prefix \\
            -xavf \\
            $args \\
            $archive \\
            $args2
    fi

    // outputs the version of tar used to a versions.yml file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        untar: \$(echo \$(tar --version 2>&1) | sed 's/^.*(GNU tar) //; s/ Copyright.*\$//')
    END_VERSIONS
    """

    // stub section for dry-run extraction to simulate file structure
    stub:
    // initializes prefix variable for stub extraction
    prefix    = task.ext.prefix ?: ( meta.id ? "${meta.id}" : archive.toString().replaceFirst(/\.[^\.]+(.gz)?$/, ""))
    // creates the output directory for the stub
    """
    mkdir ${prefix}
    // checks if the top level of the tar contents is a single directory for stub extraction
    if [[ \$(tar -taf ${archive} | grep -o -P "^.*?\\/" | uniq | wc -l) -eq 1 ]]; then
        // iterates over the contents to create directories or files as needed
        for i in `tar -tf ${archive}`;
        do
            if [[ \$(echo "\${i}" | grep -E "/\$") == "" ]];
            then
                touch \${i}
            else
                mkdir -p \${i}
            fi
        done
    else
        // iterates over the contents with prefix for stub extraction
        for i in `tar -tf ${archive}`;
        do
            if [[ \$(echo "\${i}" | grep -E "/\$") == "" ]];
            then
                touch ${prefix}/\${i}
            else
                mkdir -p ${prefix}/\${i}
            fi
        done
    fi

    // outputs the version of tar used to a versions.yml file for stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        untar: \$(echo \$(tar --version 2>&1) | sed 's/^.*(GNU tar) //; s/ Copyright.*\$//')
    END_VERSIONS
    """
}
```