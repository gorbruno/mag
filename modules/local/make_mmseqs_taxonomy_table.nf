process MAKE_MMSEQS_TAXONOMY_TABLE {

    conda "conda-forge::python=3.12.8 conda-forge::pandas=2.2.3 conda-forge::xlsxwriter=3.2.2 conda-forge::biopython=1.85"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-77320db00eefbbf8c599692102c3d387a37ef02a:08144a66f00dc7684fad061f1466033c0176e7ad-0' :
        'quay.io/biocontainers/mulled-v2-77320db00eefbbf8c599692102c3d387a37ef02a:08144a66f00dc7684fad061f1466033c0176e7ad-0' }"

    input:
    tuple val(meta), path('mmseqs2/*')
    tuple val(meta2), path('contigs/*')

    output:
    tuple val(meta), path("*.csv")       , emit: csv
    tuple val(meta), path("*.xlsx")      , optional: true, emit: excel
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args       ?: ''
    """
    make_mmseqs_taxonomy_table.py \\
        --contigs_file_prefix "${meta.assembler}-" \\
        --database ${meta.mmseqs2_db_name}
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
