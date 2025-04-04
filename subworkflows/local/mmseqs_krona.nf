include { MMSEQS_EASYTAXONOMY               } from '../../modules/local/mmseqs_easytaxonomy'
include { MAKE_MMSEQS_TAXONOMY_TABLE        } from '../../modules/local/make_mmseqs_taxonomy_table'

workflow MMSEQS_KRONA {
    take:
    contigs   // channel: [ val(meta), path(contigs) ]
    mmseqs_db // channel: [ val(meta), path(mmseqs_db) ]
    assembler // channel: [ val(assembler) ]

    main:

    ch_versions = Channel.empty()
    //
    // Mark empty contigs
    //
    ch_checked_contigs = contigs.filter { meta, file ->
    def isEmpty = file.withInputStream { stream ->
        def gzipStream = new java.util.zip.GZIPInputStream(stream)
        def reader = new BufferedReader(new InputStreamReader(gzipStream))
        return reader.readLine() == null
    }
    def meta_new = meta + [ is_empty: isEmpty ]
    return [ meta_new, file ]
    }
    ch_valid_contigs = ch_checked_contigs.filter { meta, _file -> !meta.is_empty }

    //
    // Run mmseqs easy-taxonomy on selected target database
    //
    if (!ch_valid_contigs.isEmpty()) {
        MMSEQS_EASYTAXONOMY(
            ch_valid_contigs,
            mmseqs_db
        )
        ch_versions = ch_versions.mix(MMSEQS_EASYTAXONOMY.out.versions)

        ch_tophit_aln = MMSEQS_EASYTAXONOMY.out.tophit_aln.map { meta, meta2, meta3, aln ->
            def meta_new = meta + meta2 + meta3
            [meta_new, aln]
        }

        ch_tophit_report = MMSEQS_EASYTAXONOMY.out.tophit_report.map { meta, meta2, meta3, t_report ->
            def meta_new = meta + meta2 + meta3
            [meta_new, t_report]
        }

        ch_tophit_files = ch_tophit_aln.map{ it -> it[1] }.mix(ch_tophit_report.map{ it -> it[1] }).collect()

        ch_mmseqs_files = ch_tophit_files
        .map { files ->
            def meta = [mmseqs2_db_name: mmseqs_db.meta.mmseqs2_db_name, assembler: assembler]
            [meta, files]
        }

        //
        // Krona plots on selected taxonomy
        //
        //TODO: add krona
    }
    else {
        // ch_report = Channel.empty()
        println "No valid contigs to process in sample ${ch_valid_contigs.meta.id}, skipping MMseqs2 taxonomy."
    }

    ch_contigs_files = ch_checked_contigs
    .filter { meta, _file -> !meta.is_empty }
    .collect{ it -> it[1] }
    .map { files ->
            def meta = [assembler: assembler]
            [meta, files]
        }

    if (!ch_contigs_files.isEmpty() && !ch_mmseqs_files.isEmpty()) {
        MAKE_MMSEQS_TAXONOMY_TABLE(
            ch_mmseqs_files,
            ch_contigs_files
        )
        ch_versions = ch_versions.mix(MAKE_MMSEQS_TAXONOMY_TABLE.out.versions)
    }
    else {
        println "No valid contigs, skipping MMseqs2 taxonomy table."
    }


    emit:
    versions      = ch_versions                           // channel: [ versions.yml ]
}
