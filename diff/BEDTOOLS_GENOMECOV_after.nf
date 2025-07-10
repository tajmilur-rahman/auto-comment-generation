```
// this process generates genome coverage data using bedtools
process BEDTOOLS_GENOMECOV {
    // assigns a unique tag for the process
    tag "$meta.id"
    // sets a label for the process
    label 'process_single'

    // specifies the conda environment to use
    conda "${moduleDir}/environment.yml"
    // defines the container image for execution
    container 'nf-core/bedtools_coreutils:a623c13f66d5262b'

    // input section which specifies expected inputs
    input:
    // tuple consisting of metadata, intervals path, and scaling value
    tuple val(meta), path(intervals), val(scale)
    // path to sizes file
    path  sizes
    // extension for output files
    val   extension
    // sort option for output
    val   sort

    // output section which defines the expected outputs
    output:
    // tuple consisting of metadata and output path with specified extension
    tuple val(meta), path("*.${extension}"), emit: genomecov
    // output path for versions information
    path  "versions.yml"                   , emit: versions

    // condition to determine when the process should run
    when:
    task.ext.when == null || task.ext.when

    // script section containing the command to be executed
    script:
    // retrieves additional arguments for the command, defaulting to an empty string
    def args      = task.ext.args  ?: ''
    // tokenizes the arguments into a list
    def args_list = args.tokenize()
    // appends scale option if conditions are met
    args += (scale > 0 && scale != 1) ? " -scale $scale" : ""
    // adds background option if not already included and scale conditions are met
    if (!args_list.contains('-bg') && (scale > 0 && scale != 1)) {
        args += " -bg"
    }
    // Sorts output file by chromosome and position using additional options for performance and consistency
    // See https://www.biostars.org/p/66927/ for further details
    // sets buffer size for memory if specified
    def buffer   = task.memory ? "--buffer-size=${task.memory.toGiga().intdiv(2)}G" : ''
    // creates sort command if sorting is required
    def sort_cmd = sort ? "| LC_ALL=C sort --parallel=$task.cpus $buffer -k1,1 -k2,2n" : ''

    // sets a prefix for output files based on metadata
    def prefix = task.ext.prefix ?: "${meta.id}"
    // checks if the intervals file is a BAM file
    if (intervals.name =~ /\.bam/) {
        """
        // runs bedtools genomecov with input BAM file
        bedtools \\
            genomecov \\
            -ibam $intervals \\
            $args \\
            $sort_cmd \\
            > ${prefix}.${extension}

        // writes bedtools version information to versions.yml
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            bedtools: \$(bedtools --version | sed -e "s/bedtools v//g")
        END_VERSIONS
        """
    } else {
        // runs bedtools genomecov with input intervals file
        """
        bedtools \\
            genomecov \\
            -i $intervals \\
            -g $sizes \\
            $args \\
            $sort_cmd \\
            > ${prefix}.${extension}

        // writes bedtools version information to versions.yml
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            bedtools: \$(bedtools --version | sed -e "s/bedtools v//g")
        END_VERSIONS
        """
    }

    // stub section for creating placeholder output
    stub:
    // sets a prefix for output files based on metadata
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    // creates an empty file with the specified prefix and extension
    touch  ${prefix}.${extension}

    // writes bedtools version information to versions.yml
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(bedtools --version | sed -e "s/bedtools v//g")
    END_VERSIONS
    """
}
```