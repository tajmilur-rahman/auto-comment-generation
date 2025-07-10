```
// this process extracts splice sites using HISAT2
process HISAT2_EXTRACTSPLICESITES {
    
    // sets a tag for the process
    tag "$gtf"
    
    // assigns a label for process categorization
    label 'process_medium'

    // specifies the conda environment to use
    conda "${moduleDir}/environment.yml"
    
    // sets the container image based on the workflow settings
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hisat2:2.2.1--h1b792b2_3' :
        'biocontainers/hisat2:2.2.1--h1b792b2_3' }"

    // input section for the process
    input:
    // defines input as a tuple of metadata and path to gtf file
    tuple val(meta), path(gtf)

    // output section for the process
    output:
    // defines output as a tuple of metadata and path to the splice sites text file, emits txt
    tuple val(meta), path("*.splice_sites.txt"), emit: txt
    // defines output path for the versions file, emits versions
    path "versions.yml"                        , emit: versions

    // condition for when the process should run
    when:
    // checks if a specific condition is met for execution
    task.ext.when == null || task.ext.when

    // script section containing the commands to run
    script:
    // retrieves additional arguments if provided
    def args = task.ext.args ?: ''
    """
    // runs the HISAT2 script to extract splice sites and redirect output to a file
    hisat2_extract_splice_sites.py $gtf > ${gtf.baseName}.splice_sites.txt
    // creates a versions.yml file with the version of HISAT2
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hisat2: \$(hisat2 --version | grep -o 'version [^ ]*' | cut -d ' ' -f 2)
    END_VERSIONS
    """

    // stub section for testing purposes
    stub:
    // creates an empty splice sites text file for stubbing
    """
    touch ${gtf.baseName}.splice_sites.txt

    // creates a versions.yml file with the version of HISAT2
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hisat2: \$(hisat2 --version | grep -o 'version [^ ]*' | cut -d ' ' -f 2)
    END_VERSIONS
    """
}
```