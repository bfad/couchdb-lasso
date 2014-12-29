define couchResponse_allStats => type { parent couchResponse
    public onCreate(...) => {
        ..onCreate(:#rest || (:))
    }

    public
        couchDB              => .find(`couchDB`),
        httpd                => .find(`httpd`),
        httpd_requestMethods => .find(`httpd_request_methods`),
        httpd_statusCodes    => .find(`httpd_status_codes`)
}