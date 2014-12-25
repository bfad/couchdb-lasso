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
        .currentRequest = http_request(
            .protocol + '://' + .host + ':' + .port + '/',
            -headers = (:`Accept` = "application/json")
        )
        .currentResponse = .currentRequest->response

        return json_decode(.currentResponse->bodyString)
    }



    // Introspection Accessors
    public
        currentRequest  => .`currentRequest`,
        currentResponse => .`currentResponse`
}