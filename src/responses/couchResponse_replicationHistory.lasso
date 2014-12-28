define couchResponse_replicationHistory => type { parent couchResponse
    public onCreate(...) => {
        ..onCreate(:#rest || (:))
    }

    public
        sessionID         => .find(`session_id`),
        docsRead          => .find(`docs_read`),
        docsWritten       => .find(`docs_written`),
        docWriteFailures  => .find(`doc_write_failures`),
        missingChecked    => .find(`missing_checked`),
        missingFound      => .find(`missing_found`),
        recordedSequence  => .find(`recorded_seq`),
        startLastSequence => .find(`start_last_seq`),
        endLastSequence   => .find(`end_last_seq`),
        startTime         => date(.find(`start_time`), -format=`E, dd MMM y HH:mm:ss Z`),
        endTime           => date(.find(`end_time`), -format=`E, dd MMM y HH:mm:ss Z`)
}