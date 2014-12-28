define couchResponse_replication => type { parent couchResponse
    public onCreate(...) => {
        ..onCreate(:#rest || (:))
    }

    public
        replicationIdVersion => .find(`replication_id_version`),
        ok                   => .find(`ok`),
        sessionID            => .find(`session_id`),
        sourceLastSequence   => .find(`source_last_seq`),
        history              => object_map_array(.find(`history`), ::couchResponse_replicationHistory)
}