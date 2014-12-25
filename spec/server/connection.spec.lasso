local(path_here) = currentCapture->callsite_file->stripLastComponent
not #path_here->beginsWith('/')? #path_here = io_file_getcwd + '/' + #path_here
not #path_here->endsWith('/')  ? #path_here->append('/')
not var_defined('_couch_loaded')
    ? sourcefile(file(#path_here + '../spec_helper.inc'), -autoCollect=false)->invoke


describe(::couchDB_server) => {
    it(`sets the hostname and port to the values specified in the connection string`) => {
        local(server) = couchDB_server('localhost:122345678')

        expect('localhost', #server->host)
        expect(122345678  , #server->port)
    }

    it(`defaults the port to 5984 when not passed in the connection string`) => {
        local(server) = couchDB_server('www.example.com')

        expect('www.example.com', #server->host)
        expect(5984             , #server->port)
    }

    it(`defaults the protocol to HTTPS`) => {
        local(server) = couchDB_server('www.example.com')

        expect('https', #server->protocol)
    }

    it(`sets the protocol to HTTP when passed the -noSSL flag`) => {
        local(server) = couchDB_server('localhost', -noSSL)

        expect('http', #server->protocol)
    }
}