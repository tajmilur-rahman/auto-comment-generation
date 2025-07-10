```
// this process runs FASTQC to analyze the quality of sequencing data
process FASTQC {
    // tags the process with a unique identifier
    tag "$meta.id"
    // labels the process with a specified label
    label 'process_medium'

    // specifies the conda environment used for the process
    conda "${moduleDir}/environment.yml"
    // defines the container image to be used based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0' :
        'biocontainers/fastqc:0.12.1--hdfd78af_0' }"

    // input section defining the expected inputs for the process
    input:
    // creates a tuple of metadata and reads file path
    tuple val(meta), path(reads)

    // output section defining the expected outputs of the process
    output:
    // outputs a tuple of metadata and HTML report file path
    tuple val(meta), path("*.html"), emit: html
    // outputs a tuple of metadata and ZIP file path
    tuple val(meta), path("*.zip") , emit: zip
    // outputs a versions file path
    path  "versions.yml"           , emit: versions

    // defines a condition under which the process will run
    when:
    task.ext.when == null || task.ext.when

    // script section where the main processing commands are defined
    script:
    // retrieves additional arguments or sets a default value
    def args = task.ext.args ?: ''
    // retrieves or sets a default prefix for output files
    def prefix = task.ext.prefix ?: "${meta.id}"
    // creates a list of old and new filename pairs for renaming
    def old_new_pairs = reads instanceof Path || reads.size() == 1 ? [[ reads, "${prefix}.${reads.extension}" ]] : reads.withIndex().collect { entry, index -> [ entry, "${prefix}_${index + 1}.${entry.extension}" ] }
    // joins the old and new names into a single string for use in the bash loop
    def rename_to = old_new_pairs*.join(' ').join(' ')
    // collects the new names into a string for processing
    def renamed_files = old_new_pairs.collect{ old_name, new_name -> new_name }.join(' ')

    // calculates the memory allocated for FastQC based on threads and memory
    // https://github.com/s-andrews/FastQC/blob/1faeea0412093224d7f6a07f777fad60a5650795/fastqc#L211-L222
    // ensures that the memory used is within the requested limits
    def memory_in_mb = MemoryUnit.of("${task.memory}").toUnit('MB') / task.cpus
    // sets FastQC memory to be within the allowed range (100 - 10000)
    def fastqc_memory = memory_in_mb > 10000 ? 10000 : (memory_in_mb < 100 ? 100 : memory_in_mb)

    // bash commands for renaming files and running FastQC
    """
    printf "%s %s\\n" $rename_to | while read old_name new_name; do
        [ -f "\${new_name}" ] || ln -s \$old_name \$new_name
    done

    fastqc \\
        $args \\
        --threads $task.cpus \\
        --memory $fastqc_memory \\
        $renamed_files

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$( fastqc --version | sed '/FastQC v/!d; s/.*v//' )
    END_VERSIONS
    """

    // stub section for creating placeholder outputs if the main script does not run
    stub:
    // retrieves or sets a default prefix for stub output files
    def prefix = task.ext.prefix ?: "${meta.id}"
    // creates placeholder HTML and ZIP files and version file
    """
    touch ${prefix}.html
    touch ${prefix}.zip

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$( fastqc --version | sed '/FastQC v/!d; s/.*v//' )
    END_VERSIONS
    """
}
```