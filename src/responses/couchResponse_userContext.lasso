define couchResponse_userContext => type { parent couchResponse
    public onCreate(...) => {
        ..onCreate(:#rest || (:))
    }

    public
        db    => .find(`db`),
        name  => .find(`name`),
        roles => .find(`roles`)
}