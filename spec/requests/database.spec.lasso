local(path_here) = currentCapture->callsite_file->stripLastComponent
not #path_here->beginsWith('/')? #path_here = io_file_getcwd + '/' + #path_here
not #path_here->endsWith('/')  ? #path_here->append('/')
not var_defined('_couch_loaded')
    ? sourcefile(file(#path_here + '../spec_helper.inc'), -autoCollect=false)->invoke


describe(::couchDB_database) => {
    it(`creates a copy of the couchDB_server it's passed`) => {
        local(server) = mock_server_no_auth
        local(db)     = couchDB_database(#server, 'myDB')

        #db->server->username = 'Bob'

        expect('Bob', #db->server->username)
        expect(''   , #server->username)
    }

    local(database) = couchDB_database(couchDB_server('bad_domain'), 'name')

    describe(`-> exists`) => {
        it(`creates a request with the proper path and method`) => {
            protect => { #database->exists }
            local(req) = #database->server->currentRequest

            expect('/name', #req->urlPath)
            expect('HEAD' , #req->method)
        }
    }
}