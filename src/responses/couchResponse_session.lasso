define couchResponse_session => type { parent couchResponse
    public onCreate(...) => {
        ..onCreate(:#rest || (:))
    }

    public
        authenticated          => .find(`authenticated`),
        authenticationDB       => .find(`authentication_db`),
        authenticationHandlers => .find(`authentication_handlers`),
        userContext            => couchResponse_userContext(.find(`userCtx`))
}