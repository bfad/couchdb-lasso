define couchResponse_documentMetaData => type { parent couchResponse
    public onCreate(...) => {
        ..onCreate(:#rest || (:))
    }

    public
        id   => .find(`id`),
        key  => .find(`key`),
        rev  => .find(`value`)->find(`rev`),
        data => .find(`doc`)
}