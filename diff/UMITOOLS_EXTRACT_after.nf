```
// this process extracts UMI from sequencing reads using umi_tools
process UMITOOLS_EXTRACT {
    // tags the process with a unique identifier
    tag "$meta.id"
    
    // assigns a short label to the process
    label "process_single"
    
    // assigns a long label to the process
    label "process_long"

    // specifies the conda environment to be used
    conda "${moduleDir}/environment.yml"
    
    // determines the container image based on the workflow settings
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/umi_tools:1.1.5--py39hf95cd2a_0' :
        'biocontainers/umi_tools:1.1.5--py39hf95cd2a_0' }"

    // input section defining the expected input types
    input:
    // tuple containing metadata and path to reads
    tuple val(meta), path(reads)

    // output section defining the expected output types
    output:
    // tuple for the extracted reads in fastq.gz format
    tuple val(meta), path("*.fastq.gz"), emit: reads
    // tuple for the log file
    tuple val(meta), path("*.log")     , emit: log
    // path for the versions file
    path  "versions.yml"               , emit: versions

    // condition to execute the task based on external criteria
    when:
    task.ext.when == null || task.ext.when

    // script section containing the commands to be executed
    script:
    // initializes arguments and prefix for output files
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    // checks if the reads are single-end
    if (meta.single_end) {
        """
        // command to extract UMI from single-end reads
        umi_tools \\
            extract \\
            -I $reads \\
            -S ${prefix}.umi_extract.fastq.gz \\
            $args \\
            > ${prefix}.umi_extract.log

        // writes the versions of umi_tools to a file
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            umitools: \$( umi_tools --version | sed '/version:/!d; s/.*: //' )
        END_VERSIONS
        """
    }  else {
        // command to extract UMI from paired-end reads
        """
        umi_tools \\
            extract \\
            -I ${reads[0]} \\
            --read2-in=${reads[1]} \\
            -S ${prefix}.umi_extract_1.fastq.gz \\
            --read2-out=${prefix}.umi_extract_2.fastq.gz \\
            $args \\
            > ${prefix}.umi_extract.log

        // writes the versions of umi_tools to a file
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            umitools: \$( umi_tools --version | sed '/version:/!d; s/.*: //' )
        END_VERSIONS
        """
    }

    // stub section for generating placeholder outputs
    stub:
    // initializes prefix for output files
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    // checks if the reads are single-end
    if (meta.single_end) {
        // command to create an empty gzip file for single-end output
        output_command = "echo '' | gzip > ${prefix}.umi_extract.fastq.gz"
    } else {
        // commands to create empty gzip files for paired-end output
        output_command = "echo '' | gzip > ${prefix}.umi_extract_1.fastq.gz ;"
        output_command += "echo '' | gzip > ${prefix}.umi_extract_2.fastq.gz"
    }
    
    // commands to create a log file and the output gzip files
    """
    touch ${prefix}.umi_extract.log
    ${output_command}

    // writes the versions of umi_tools to a file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        umitools: \$( umi_tools --version | sed '/version:/!d; s/.*: //' )
    END_VERSIONS
    """
}
```