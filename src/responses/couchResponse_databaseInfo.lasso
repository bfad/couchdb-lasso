define couchResponse_databaseInfo => type { parent couchResponse
    public onCreate(...) => {
        ..onCreate(:#rest || (:))
    }

    public
        committedUpdateSequences => .find(`committed_update_seq`),
        isCompactRunning         => .find(`compact_running`),
        dataSize                 => .find(`data_size`),
        name                     => .find(`db_name`),
        diskFormatVersion        => .find(`disk_format_version`),
        diskSize                 => .find(`disk_size`),
        documentCount            => .find(`doc_count`),
        documentDeleteCount      => .find(`doc_del_count`),
        instanceStartTime        => date(integer(.find(`instance_start_time`))),
        purgeSequences           => .find(`purge_seq`),
        updateSequences          => .find(`update_seq`)
}