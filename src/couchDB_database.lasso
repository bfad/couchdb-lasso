define couchDB_database => type {
    data
        public name,
        private server

    public onCreate(server::couchDB_server, name::string) => {
        #server = #server->asCopy

        #server->clearRequest

        .server = #server
        .name   = #name
    }


    public
        server   => .`server`,
        basePath => '/' + .name


    public exists => {
        .server->generateRequest(
            .basePath,
            -method = "HEAD"
        )
        // Because 404 errors are expected (maybe turn this into try so other errors fall through?)
        protect => { .server->makeRequest }

        return .server->currentResponse->statusCode == 200
    }
}
