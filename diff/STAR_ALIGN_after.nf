```
// this process performs STAR alignment for RNA-Seq data
process STAR_ALIGN {
    // assigns a unique tag for the process
    tag "$meta.id"
    // sets a label for process grouping
    label 'process_high'

    // specifies the conda environment to use
    conda "${moduleDir}/environment.yml"
    // specifies the Docker container to use
    container 'nf-core/htslib_samtools_star_gawk:311d422a50e6d829'

    // input section defining the required input files and parameters
    input:
    // input tuple for metadata and reads
    tuple val(meta), path(reads, stageAs: "input*/*")
    // input tuple for index file
    tuple val(meta2), path(index)
    // input tuple for GTF file
    tuple val(meta3), path(gtf)
    // additional input values
    val star_ignore_sjdbgtf
    val seq_platform
    val seq_center

    // output section defining the produced output files
    output:
    // output tuple for final log file
    tuple val(meta), path('*Log.final.out')   , emit: log_final
    // output tuple for intermediate log file
    tuple val(meta), path('*Log.out')         , emit: log_out
    // output tuple for progress log file
    tuple val(meta), path('*Log.progress.out'), emit: log_progress
    // output path for versions file
    path  "versions.yml"                      , emit: versions

    // optional output tuples for various BAM files
    tuple val(meta), path('*d.out.bam')                              , optional:true, emit: bam
    tuple val(meta), path("${prefix}.sortedByCoord.out.bam")         , optional:true, emit: bam_sorted
    tuple val(meta), path("${prefix}.Aligned.sortedByCoord.out.bam") , optional:true, emit: bam_sorted_aligned
    tuple val(meta), path('*toTranscriptome.out.bam')                , optional:true, emit: bam_transcript
    tuple val(meta), path('*Aligned.unsort.out.bam')                 , optional:true, emit: bam_unsorted
    tuple val(meta), path('*fastq.gz')                               , optional:true, emit: fastq
    tuple val(meta), path('*.tab')                                   , optional:true, emit: tab
    tuple val(meta), path('*.SJ.out.tab')                            , optional:true, emit: spl_junc_tab
    tuple val(meta), path('*.ReadsPerGene.out.tab')                  , optional:true, emit: read_per_gene_tab
    tuple val(meta), path('*.out.junction')                          , optional:true, emit: junction
    tuple val(meta), path('*.out.sam')                               , optional:true, emit: sam
    tuple val(meta), path('*.wig')                                   , optional:true, emit: wig
    tuple val(meta), path('*.bg')                                    , optional:true, emit: bedgraph

    // conditional execution based on the presence of a 'when' clause
    when:
    task.ext.when == null || task.ext.when

    // script section defining the commands to run
    script:
    // initializes arguments and prefix variables
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    // initializes lists for separated reads
    def reads1 = [], reads2 = []
    // separates reads based on single-end or paired-end
    meta.single_end ? [reads].flatten().each{reads1 << it} : reads.eachWithIndex{ v, ix -> ( ix & 1 ? reads2 : reads1) << v }
    // determines whether to ignore GTF file based on input
    def ignore_gtf      = star_ignore_sjdbgtf ? '' : "--sjdbGTFfile $gtf"
    // sets sequencing platform and center attributes
    def seq_platform    = seq_platform ? "'PL:$seq_platform'" : ""
    def seq_center      = seq_center ? "'CN:$seq_center'" : ""
    // constructs attribute line for SAM output
    attrRG          = args.contains("--outSAMattrRGline") ? "" : "--outSAMattrRGline 'ID:$prefix' $seq_center 'SM:$prefix' $seq_platform"
    // determines output SAM type based on input arguments
    def out_sam_type    = (args.contains('--outSAMtype')) ? '' : '--outSAMtype BAM Unsorted'
    // defines command to move unsorted BAM file if necessary
    mv_unsorted_bam = (args.contains('--outSAMtype BAM Unsorted SortedByCoordinate')) ? "mv ${prefix}.Aligned.out.bam ${prefix}.Aligned.unsort.out.bam" : ''
    // constructs the STAR command with parameters
    """
    STAR \\
        --genomeDir $index \\
        --readFilesIn ${reads1.join(",")} ${reads2.join(",")} \\
        --runThreadN $task.cpus \\
        --outFileNamePrefix $prefix. \\
        $out_sam_type \\
        $ignore_gtf \\
        $attrRG \\
        $args

    $mv_unsorted_bam

    // checks for unmapped reads and processes them
    if [ -f ${prefix}.Unmapped.out.mate1 ]; then
        mv ${prefix}.Unmapped.out.mate1 ${prefix}.unmapped_1.fastq
        gzip ${prefix}.unmapped_1.fastq
    fi
    if [ -f ${prefix}.Unmapped.out.mate2 ]; then
        mv ${prefix}.Unmapped.out.mate2 ${prefix}.unmapped_2.fastq
        gzip ${prefix}.unmapped_2.fastq
    fi

    // generates a versions file with software versions used
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed -e "s/STAR_//g")
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        gawk: \$(echo \$(gawk --version 2>&1) | sed 's/^.*GNU Awk //; s/, .*\$//')
    END_VERSIONS
    """

    // stub section providing placeholders for output files
    stub:
    // initializes prefix variable for stub outputs
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    // creates empty gzip files for unmapped reads
    echo "" | gzip > ${prefix}.unmapped_1.fastq.gz
    echo "" | gzip > ${prefix}.unmapped_2.fastq.gz
    // creates placeholder output files
    touch ${prefix}Xd.out.bam
    touch ${prefix}.Log.final.out
    touch ${prefix}.Log.out
    touch ${prefix}.Log.progress.out
    touch ${prefix}.sortedByCoord.out.bam
    touch ${prefix}.toTranscriptome.out.bam
    touch ${prefix}.Aligned.unsort.out.bam
    touch ${prefix}.Aligned.sortedByCoord.out.bam
    touch ${prefix}.tab
    touch ${prefix}.SJ.out.tab
    touch ${prefix}.ReadsPerGene.out.tab
    touch ${prefix}.Chimeric.out.junction
    touch ${prefix}.out.sam
    touch ${prefix}.Signal.UniqueMultiple.str1.out.wig
    touch ${prefix}.Signal.UniqueMultiple.str1.out.bg

    // generates a versions file with software versions for the stub
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed -e "s/STAR_//g")
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        gawk: \$(echo \$(gawk --version 2>&1) | sed 's/^.*GNU Awk //; s/, .*\$//')
    END_VERSIONS
    """
}
```