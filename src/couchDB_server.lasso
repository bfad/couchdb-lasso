define couchDB_server => type {
    data
        public protocol::string,
        public host::string,
        public port::integer,

        private currentRequest,
        private currentResponse


    public onCreate(connection::string, -noSSL::boolean=false) => {
        local(host, port) = #connection->split(':')

        .host     = #host
        .port     = (#port  ? integer(#port) | 5984   )
        .protocol = (#noSSL ? 'http'         | 'https')
    }


    public info => {
        .generateRequest(
            '/',
            -headers = (:`Accept` = "application/json")
        )

        return json_decode(.currentResponse->bodyString)
    }

// TODO: Custom Type
    public activeTasks => {
        .generateRequest(
            '/_active_tasks',
            -headers = (:`Accept` = "application/json")
        )
        
        return json_decode(.currentResponse->bodyString)
    }

    public allDBs => {
        .generateRequest(
            '/_all_dbs',
            -headers = (:`Accept` = "application/json")
        )

        return json_decode(.currentResponse->bodyString)
    }

    public dbUpdates(feed::string, -timeout::integer=60, -noHeartbeat::boolean=false) => {
        (:'longpoll', 'continuous', 'eventsource') !>> #feed
            ? fail(error_code_invalidParameter, "Invalid parameter passed to feed")


        .generateRequest(
            '/_db_updates',
            -headers   = (:`Accept` = "application/json"),
            -getParams = (:`feed` = #feed, `timeout` = #timeout, `heartbeat` = not #noHeartbeat)

        )

        return json_decode(.currentResponse->bodyString)
    }

    public log(-offset::integer=0, -bytes::integer=1000) => {
        .generateRequest(
            '/_log',
            -headers   = (:`Accept` = "text/plain; charset=utf-8"),
            -getParams = (:`offset` = #offset, `bytes` = #bytes)
        )

        return json_decode(.currentResponse->bodyString)
    }



    // Introspection Accessors
    public
        currentRequest  => .`currentRequest`,
        currentResponse => .`currentResponse` || .`currentResponse` := .currentRequest->response



    private generateRequest(path::string, ...) => {
        .currentRequest  = http_request(:(:.protocol + '://' + .host + ':' + .port + #path) + (#rest || (:)))
        .currentResponse = null
    }
}