define couchResponse_allDocuments => type { parent couchResponse
    public onCreate(...) => {
        ..onCreate(:#rest || (:))
    }

    public
        offset         => .find(`offset`),
        rows           => object_map_array(.find(`rows`), ::couchResponse_documentMetaData),
        totalRows      => .find(`total_rows`),
        updateSequence => .find(`update_seq`)
}