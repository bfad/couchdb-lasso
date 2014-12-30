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
        basePath => '/' + .name->encodeUrl


    public exists => {
        .server->generateRequest(
            .basePath,
            -method = "HEAD"
        )
        // Because 404 errors are expected (maybe turn this into try so other errors fall through?)
        protect => { .server->makeRequest }

        return .server->currentResponse->statusCode == 200
    }

    public info => {
        .server->generateRequest(
            .basePath,
            -headers = (:`Accept` = "application/json")
        )

        return couchResponse_databaseInfo(json_decode(.server->currentResponse->bodyString))
    }

    public create => {
        .server->generateRequest(
            .basePath,
            -method  = "PUT",
            -headers = (:`Accept` = "application/json")
        )

        .server->currentResponse
    }

    public delete => {
        .server->generateRequest(
            .basePath,
            -method  = "DELETE",
            -headers = (:`Accept` = "application/json")
        )

        .server->currentResponse
    }

    public createDocument(
        data::map,
        -waitForWrite::boolean=false,
        -noWaitForWrite::boolean=false,
        -batchMode::boolean=false
    ) => {
        local(headers)      = array(`Accept` = "application/json", `Content-Type` = "application/json")
        local(query_params) = array

        #waitForWrite and #noWaitForWrite
            ? fail("It is a contradiction to specify to both wait and not wait for writes")
        #waitForWrite
            ? #headers->insert(`X-Couch-Full-Commit` = "true")
        #noWaitForWrite
            ? #headers->insert(`X-Couch-Full-Commit` = "false")

        #batchMode
            ? #query_params->insert(`batch`='ok')

        .server->generateRequest(
            .basePath,
            -method     = "POST",
            -headers    = #headers,
            -getParams  = #query_params,
            -postParams = json_encode(#data)
        )

        return json_decode(.server->currentResponse->bodyString)
    }
}
