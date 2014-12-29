define couchResponse_stat => type { parent couchResponse
    public onCreate(...) => {
        ..onCreate(:#rest || (:))
    }

    public
        sectionName => .find(`sectionName`),
        name        => .find(`name`),
        description => .find(`description`),
        current     => .find(`current`),
        sum         => .find(`sum`),
        mean        => .find(`mean`),
        stddev      => .find(`stddev`),
        min         => .find(`min`),
        max         => .find(`max`)
}