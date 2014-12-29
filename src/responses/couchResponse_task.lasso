define couchResponse_task => type { parent couchResponse
    public onCreate(...) => {
        ..onCreate(:#rest || (:))
    }

    public
        pid          => .find(`pid`),
        name         => .find(`task`),
        status       => .find(`status`),
        taskType     => .find(`type`),
        database     => .find(`database`),
        progress     => .find(`progress`),
        changesDone  => .find(`changes_done`),
        totalChanges => .find(`total_changes`),
        started      => date(.find(`started_on`)),
        updated      => date(.find(`updated_on`))
}