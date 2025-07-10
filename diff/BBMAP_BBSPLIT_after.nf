```
// this process manages the BBMAP BBSPLIT workflow
process BBMAP_BBSPLIT {
    // tags the process with the meta ID
    tag "$meta.id"
    // assigns a high priority label to the process
    label 'process_high'
    // assigns an error retry label to the process
    label 'error_retry'

    // specifies the conda environment for the process
    conda "${moduleDir}/environment.yml"
    // sets the container image based on the workflow container engine
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bbmap:39.10--h92535d8_0':
        'biocontainers/bbmap:39.10--h92535d8_0' }"

    // input section defining the required input data
    input:
    // tuple containing meta information and read paths
    tuple val(meta), path(reads)
    // path for the index file
    path  index
    // path for the primary reference file
    path  primary_ref
    // tuple containing other reference names and their paths
    tuple val(other_ref_names), path(other_ref_paths)
    // flag to determine if only the index should be built
    val   only_build_index

    // output section defining the expected output data
    output:
    // optional output path for bbsplit, emits index
    path "bbsplit"                            , optional:true, emit: index
    // optional output tuple for primary fastq files, emits primary_fastq
    tuple val(meta), path('*primary*fastq.gz'), optional:true, emit: primary_fastq
    // optional output tuple for all fastq files, emits all_fastq
    tuple val(meta), path('*fastq.gz')        , optional:true, emit: all_fastq
    // optional output tuple for stats files, emits stats
    tuple val(meta), path('*txt')             , optional:true, emit: stats
    // optional output tuple for log files, emits log
    tuple val(meta), path('*.log')            , optional:true, emit: log
    // output path for versions.yml, emits versions
    path "versions.yml"                       , emit: versions

    // conditional execution based on the when clause
    when:
    task.ext.when == null || task.ext.when

    // script section containing the main logic of the process
    script:
    // retrieves additional arguments or sets a default
    def args = task.ext.args ?: ''
    // sets a prefix for output files
    def prefix = task.ext.prefix ?: "${meta.id}"

    // initializes available memory
    def avail_mem = 3072
    // checks if memory is specified and adjusts available memory accordingly
    if (!task.memory) {
        log.info '[BBSplit] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    // initializes an array for other reference paths
    def other_refs = []
    // populates the other_refs array with references and their paths
    other_ref_names.eachWithIndex { name, index ->
        other_refs << "ref_${name}=${other_ref_paths[index]}"
    }

    // initializes variables for fastq input/output and index files
    def fastq_in=''
    def fastq_out=''
    def index_files=''
    def refstats_cmd=''

    // checks if only the index should be built
    if (only_build_index) {
        // validates primary reference and other references, constructs index files
        if (primary_ref && other_ref_names && other_ref_paths) {
            index_files = 'ref_primary=' +primary_ref + ' ' + other_refs.join(' ') + ' path=bbsplit'
        } else {
            log.error 'ERROR: Please specify as input a primary fasta file along with names and paths to non-primary fasta files.'
        }
    } else {
        // checks for index input or primary reference
        if (index) {
            index_files = "path=$index"
        } else if (primary_ref && other_ref_names && other_ref_paths) {
            index_files = "ref_primary=${primary_ref} ${other_refs.join(' ')}"
        } else {
            log.error 'ERROR: Please either specify a BBSplit index as input or a primary fasta file along with names and paths to non-primary fasta files.'
        }
        // constructs fastq input/output strings based on single-end or paired-end
        fastq_in  = meta.single_end ? "in=${reads}" : "in=${reads[0]} in2=${reads[1]}"
        fastq_out = meta.single_end ? "basename=${prefix}_%.fastq.gz" : "basename=${prefix}_%_#.fastq.gz"
        refstats_cmd = 'refstats=' + prefix + '.stats.txt'
    }
    """

    # Adjust timestamps in summary files to avoid issues with BBSplit
    if [ $index ]; then
        for summary_file in \$(find $index/ref/genome -name summary.txt); do
            src=\$(grep '^source' "\$summary_file" | cut -f2- -d\$'\\t' | sed 's|.*/bbsplit|bbsplit|')
            mod=\$(echo "System.out.println(java.nio.file.Files.getLastModifiedTime(java.nio.file.Paths.get(\\"\$src\\")).toMillis());" | jshell -J-Djdk.lang.Process.launchMechanism=vfork -)
            sed "s|^last modified.*|last modified\\t\$mod|" "\$summary_file" > \${summary_file}.tmp && mv \${summary_file}.tmp \${summary_file}
        done
    fi

    # Executes the BBSplit command with specified parameters
    bbsplit.sh \\
        -Xmx${avail_mem}M \\
        $index_files \\
        threads=$task.cpus \\
        $fastq_in \\
        $fastq_out \\
        $refstats_cmd \\
        $args 2> >(tee ${prefix}.log >&2)

    # Fixes source paths in summary files to make them usable in other processes
    for summary_file in \$(find bbsplit/ref/genome -name summary.txt); do
        src=\$(grep '^source' "\$summary_file" | cut -f2- -d\$'\\t' | sed 's|.*/bbsplit|bbsplit|')
        sed "s|^source.*|source\\t\$src|" "\$summary_file" > \${summary_file}.tmp && mv \${summary_file}.tmp \${summary_file}
    done

    // creates a versions.yml file capturing the BBMap version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bbmap: \$(bbversion.sh | grep -v "Duplicate cpuset")
    END_VERSIONS
    """

    // stub section for defining placeholder actions
    stub:
    // sets a prefix for stub output
    def prefix = task.ext.prefix ?: "${meta.id}"
    // initializes a string for other reference placeholders
    def other_refs = ''
    // adds echo commands for other references to the string
    other_ref_names.eachWithIndex { name, index ->
        other_refs += "echo '' | gzip > ${prefix}_${name}.fastq.gz"
    }
    """
    // checks if the bbsplit directory exists and creates it if not
    if [ ! -d bbsplit ]; then
        mkdir bbsplit
    fi

    // creates primary fastq file and other reference files if not building index exclusively
    if ! (${only_build_index}); then
        echo '' | gzip >  ${prefix}_primary.fastq.gz
        ${other_refs}
        touch ${prefix}.stats.txt
    fi

    // creates an empty log file for the process
    touch ${prefix}.log

    // creates a versions.yml file capturing the BBMap version again
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bbmap: \$(bbversion.sh | grep -v "Duplicate cpuset")
    END_VERSIONS
    """
}
```