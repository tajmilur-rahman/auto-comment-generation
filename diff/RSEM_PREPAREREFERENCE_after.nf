```
// this process prepares a reference for RSEM using the provided FASTA and GTF files
process RSEM_PREPAREREFERENCE {
    // tagging the process with the FASTA file
    tag "$fasta"
    // labeling the process for high priority
    label 'process_high'

    // specifying the conda environment for the process
    conda "${moduleDir}/environment.yml"
    // defining the container to be used based on the workflow's container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-cf0123ef83b3c38c13e3b0696a3f285d3f20f15b:64aad4a4e144878400649e71f42105311be7ed87-0' :
        'biocontainers/mulled-v2-cf0123ef83b3c38c13e3b0696a3f285d3f20f15b:64aad4a4e144878400649e71f42105311be7ed87-0' }"

    // defining the input files required by the process
    input:
    path fasta, stageAs: "rsem/*"
    path gtf

    // defining the output files produced by the process
    output:
    path "rsem"           , emit: index
    path "*transcripts.fa", emit: transcript_fasta
    path "versions.yml"   , emit: versions

    // determining when the process should execute based on a condition
    when:
    task.ext.when == null || task.ext.when

    // script section where the main commands are executed
    script:
    // initializing arguments for the script
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    // tokenizing the arguments for further processing
    def args_list = args.tokenize()
    // checking if the argument list contains the '--star' option
    if (args_list.contains('--star')) {
        // removing the '--star' option from the arguments
        args_list.removeIf { it.contains('--star') }
        // calculating memory limit for STAR if specified
        def memory = task.memory ? "--limitGenomeGenerateRAM ${task.memory.toBytes() - 100000000}" : ''
        // executing commands for STAR genome generation and RSEM reference preparation
        """
        STAR \\
            --runMode genomeGenerate \\
            --genomeDir rsem/ \\
            --genomeFastaFiles $fasta \\
            --sjdbGTFfile $gtf \\
            --runThreadN $task.cpus \\
            $memory \\
            $args2

        rsem-prepare-reference \\
            --gtf $gtf \\
            --num-threads $task.cpus \\
            ${args_list.join(' ')} \\
            $fasta \\
            rsem/genome

        cp rsem/genome.transcripts.fa .

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            rsem: \$(rsem-calculate-expression --version | sed -e "s/Current version: RSEM v//g")
            star: \$(STAR --version | sed -e "s/STAR_//g")
        END_VERSIONS
        """
    } else {
        // executing commands for RSEM reference preparation without STAR
        """
        rsem-prepare-reference \\
            --gtf $gtf \\
            --num-threads $task.cpus \\
            $args \\
            $fasta \\
            rsem/genome

        cp rsem/genome.transcripts.fa .

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            rsem: \$(rsem-calculate-expression --version | sed -e "s/Current version: RSEM v//g")
            star: \$(STAR --version | sed -e "s/STAR_//g")
        END_VERSIONS
        """
    }

    // stub section for handling cases when the main script fails
    stub:
    """
    touch genome.transcripts.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rsem: \$(rsem-calculate-expression --version | sed -e "s/Current version: RSEM v//g")
        star: \$(STAR --version | sed -e "s/STAR_//g")
    END_VERSIONS
    """
}
```