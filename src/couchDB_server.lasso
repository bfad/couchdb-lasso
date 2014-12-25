define couchDB_server => type {
    data
        public protocol::string,
        public host::string,
        public port::integer


    public onCreate(connection::string, -noSSL::boolean=false) => {
        local(host, port) = #connection->split(':')

        .host     = #host
        .port     = (#port? integer(#port) | 5984)
        .protocol = 'http' + (#noSSL ? '' | 's')
    }
}