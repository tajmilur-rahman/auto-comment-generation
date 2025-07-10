```
// this process runs the Bracken tool to generate reports from Kraken output
process BRACKEN_BRACKEN {
    // assigns a tag based on the metadata id
    tag "$meta.id"
    // sets a label for the process
    label 'process_low'

    // specifies the conda environment to use
    conda "${moduleDir}/environment.yml"
    // defines the container image to be used based on conditions
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bracken:2.9--py38h2494328_0':
        'biocontainers/bracken:2.9--py38h2494328_0' }"

    input:
    // expects a tuple of metadata and path to a Kraken report, along with a database path
    tuple val(meta), path(kraken_report)
    path database

    output:
    // produces a tuple of metadata and paths for the Bracken report, emitting reports
    tuple val(meta), path(bracken_report)        , emit: reports
    // produces a tuple of metadata and paths for the Kraken-style report, emitting txt
    tuple val(meta), path(bracken_kraken_style_report), emit: txt
    // outputs a path for the versions information, emitting versions
    path "versions.yml"          , emit: versions

    when:
    // specifies when the task should run based on external conditions
    task.ext.when == null || task.ext.when

    script:
    // initializes arguments and prefix for output files
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    bracken_report = "${prefix}.tsv"
    bracken_kraken_style_report = "${prefix}.kraken2.report_bracken.txt"
    """
    // runs the Bracken command with the specified arguments and input/output files
    bracken \\
        ${args} \\
        -d '${database}' \\
        -i '${kraken_report}' \\
        -o '${bracken_report}' \\
        -w '${bracken_kraken_style_report}'

    // writes the version information to versions.yml
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bracken: \$(echo \$(bracken -v) | cut -f2 -d'v')
    END_VERSIONS
    """

    stub:
    // initializes arguments and prefix for output files in the stub section
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    bracken_report = "${prefix}.tsv"
    bracken_kraken_style_report = "${prefix}.kraken2.report_bracken.txt"
    """
    // creates empty files for the expected output reports
    touch ${prefix}.tsv
    touch ${bracken_kraken_style_report}

    // writes the version information to versions.yml in the stub section
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bracken: \$(echo \$(bracken -v) | cut -f2 -d'v')
    END_VERSIONS
    """
}
```