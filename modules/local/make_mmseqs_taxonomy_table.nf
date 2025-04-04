process MAKE_MMSEQS_TAXONOMY_TABLE {

    conda "conda-forge::python=3.13.2 conda-forge::pandas=2.2.3 conda-forge::xlsxwriter=3.2.2 conda-forge::biopython=1.85"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/4f/4fb33d12be2d1117d1f9591424797bfa4491d1862ce4073a386e636b31c7072d/data' :
        'community.wave.seqera.io/library/biopython_pandas_python_xlsxwriter:bf905fc7253d1387' }"

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
