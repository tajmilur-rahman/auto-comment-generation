```
// this process handles the merging of FASTQ files based on whether they are single-end or paired-end
process CAT_FASTQ {
    // tags the process with the meta id
    tag "$meta.id"
    // labels the process for identification
    label 'process_single'

    // specifies the conda environment for the process
    conda "${moduleDir}/environment.yml"
    // specifies the container image to use for the process
    container 'nf-core/coreutils:9.5--ae99c88a9b28c264'

    // defines the input parameters for the process
    input:
    // takes a tuple of metadata and a path to the reads
    tuple val(meta), path(reads, stageAs: "input*/*")

    // defines the output parameters for the process
    output:
    // outputs a tuple of metadata and the merged FASTQ file, also emits the original reads
    tuple val(meta), path("*.merged.fastq.gz"), emit: reads
    // outputs a versions file that logs the version of the 'cat' command used
    path "versions.yml"                       , emit: versions

    // conditional execution based on a specified condition
    when:
    // executes if the condition is null or true
    task.ext.when == null || task.ext.when

    // script section where the main processing logic is defined
    script:
    // retrieves arguments and prefixes from the task extension or sets defaults
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // converts reads to a list if it's not already
    def readList = reads instanceof List ? reads.collect{ it.toString() } : [reads.toString()]
    // handles single-end reads
    if (meta.single_end) {
        // checks if there is at least one read
        if (readList.size >= 1) {
            // concatenates reads into a single merged FASTQ file and logs versions
            """
            cat ${readList.join(' ')} > ${prefix}.merged.fastq.gz

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                cat: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
            END_VERSIONS
            """
        }
    // handles paired-end reads
    } else {
        // checks if there are at least two reads
        if (readList.size >= 2) {
            def read1 = []
            def read2 = []
            // separates reads into two lists
            readList.eachWithIndex{ v, ix -> ( ix & 1 ? read2 : read1 ) << v }
            // concatenates read1 and read2 into separate merged FASTQ files and logs versions
            """
            cat ${read1.join(' ')} > ${prefix}_1.merged.fastq.gz
            cat ${read2.join(' ')} > ${prefix}_2.merged.fastq.gz

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                cat: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
            END_VERSIONS
            """
        }
    }

    // stub section for testing or placeholder functionality
    stub:
    // retrieves prefix and reads list similar to the main script section
    def prefix = task.ext.prefix ?: "${meta.id}"
    def readList = reads instanceof List ? reads.collect{ it.toString() } : [reads.toString()]
    // handles single-end reads in the stub
    if (meta.single_end) {
        // checks if there is at least one read
        if (readList.size >= 1) {
            // creates an empty merged FASTQ file for testing and logs versions
            """
            echo '' | gzip > ${prefix}.merged.fastq.gz

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                cat: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
            END_VERSIONS
            """
        }
    // handles paired-end reads in the stub
    } else {
        // checks if there are at least two reads
        if (readList.size >= 2) {
            // creates empty merged FASTQ files for testing and logs versions
            """
            echo '' | gzip > ${prefix}_1.merged.fastq.gz
            echo '' | gzip > ${prefix}_2.merged.fastq.gz

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                cat: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
            END_VERSIONS
            """
        }
    }
}
```