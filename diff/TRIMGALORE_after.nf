```
// this process performs trimming of sequencing reads using Trim Galore
process TRIMGALORE {
    // assign a unique tag to the process based on metadata
    tag "$meta.id"
    // label the process with a priority level
    label 'process_high'

    // specify the conda environment for the process
    conda "${moduleDir}/environment.yml"
    // define the container to be used based on certain conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/trim-galore%3A0.6.10--hdfd78af_1' :
        'biocontainers/trim-galore:0.6.10--hdfd78af_1' }"

    // define the input for the process
    input:
    // input is a tuple containing metadata and path to reads
    tuple val(meta), path(reads)

    // define the output for the process
    output:
    // output tuples for various results including trimmed reads and reports
    tuple val(meta), path("*{3prime,5prime,trimmed,val}*.fq.gz"), emit: reads
    tuple val(meta), path("*report.txt")                        , emit: log     , optional: true
    tuple val(meta), path("*unpaired*.fq.gz")                   , emit: unpaired, optional: true
    tuple val(meta), path("*.html")                             , emit: html    , optional: true
    tuple val(meta), path("*.zip")                              , emit: zip     , optional: true
    path "versions.yml"                                         , emit: versions

    // define when the process should run based on external conditions
    when:
    task.ext.when == null || task.ext.when

    // script section containing the main logic of the process
    script:
    // initialize args variable with external arguments or empty string
    def args = task.ext.args ?: ''
    // Calculate number of --cores for TrimGalore based on value of task.cpus
    // See: https://github.com/FelixKrueger/TrimGalore/blob/master/Changelog.md#version-060-release-on-1-mar-2019
    // See: https://github.com/nf-core/atacseq/pull/65
    // default cores set to 1
    def cores = 1
    // adjust cores based on available CPUs and single-end status
    if (task.cpus) {
        cores = (task.cpus as int) - 4
        if (meta.single_end) cores = (task.cpus as int) - 3
        if (cores < 1) cores = 1
        if (cores > 8) cores = 8
    }

    // Added soft-links to original fastqs for consistent naming in MultiQC
    // set prefix for output files based on metadata
    def prefix = task.ext.prefix ?: "${meta.id}"
    // logic for single-end reads
    if (meta.single_end) {
        // split args into a list and remove certain options
        def args_list = args.split("\\s(?=--)").toList()
        args_list.removeAll { it.toLowerCase().contains('_r2 ') }
        // command to create soft link and run trim_galore
        """
        [ ! -f  ${prefix}.fastq.gz ] && ln -s $reads ${prefix}.fastq.gz
        trim_galore \\
            ${args_list.join(' ')} \\
            --cores $cores \\
            --gzip \\
            ${prefix}.fastq.gz

        // write versions of the tools used to versions.yml
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            trimgalore: \$(echo \$(trim_galore --version 2>&1) | sed 's/^.*version //; s/Last.*\$//')
            cutadapt: \$(cutadapt --version)
        END_VERSIONS
        """
    } else {
        // logic for paired-end reads
        """
        [ ! -f  ${prefix}_1.fastq.gz ] && ln -s ${reads[0]} ${prefix}_1.fastq.gz
        [ ! -f  ${prefix}_2.fastq.gz ] && ln -s ${reads[1]} ${prefix}_2.fastq.gz
        trim_galore \\
            $args \\
            --cores $cores \\
            --paired \\
            --gzip \\
            ${prefix}_1.fastq.gz \\
            ${prefix}_2.fastq.gz

        // write versions of the tools used to versions.yml
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            trimgalore: \$(echo \$(trim_galore --version 2>&1) | sed 's/^.*version //; s/Last.*\$//')
            cutadapt: \$(cutadapt --version)
        END_VERSIONS
        """
    }

    // stub section for generating output commands when the process is run
    stub:
    // set output command based on single-end or paired-end
    def prefix = task.ext.prefix ?: "${meta.id}"
    if (meta.single_end) {
        output_command = "echo '' | gzip > ${prefix}_trimmed.fq.gz ;"
        output_command += "touch ${prefix}.fastq.gz_trimming_report.txt"
    } else {
        output_command = "echo '' | gzip > ${prefix}_1_trimmed.fq.gz ;"
        output_command += "touch ${prefix}_1.fastq.gz_trimming_report.txt ;"
        output_command += "echo '' | gzip > ${prefix}_2_trimmed.fq.gz ;"
        output_command += "touch ${prefix}_2.fastq.gz_trimming_report.txt"
    }
    // output command to be executed
    """
    ${output_command}

    // write versions of the tools used to versions.yml
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimgalore: \$(echo \$(trim_galore --version 2>&1) | sed 's/^.*version //; s/Last.*\$//')
        cutadapt: \$(cutadapt --version)
    END_VERSIONS
    """
}
```