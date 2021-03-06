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


    describe(`-> info`) => {
        it(`creates a request with the proper path and Accept header`) => {
            protect => { #database->info }
            local(req) = #database->server->currentRequest

            expect('/name', #req->urlPath)
            expect(#req->headers >> pair(`Accept` = "application/json"))
        }

        it(`properly url encodes the database name of the path`) => {
            local(db) = couchDB_database(couchDB_server('bad_domain'), 'my/name+$')
            protect => { #db->info }

            expect(`/my%2Fname%2B%24`, #db->server->currentRequest->urlPath)
        }
    }


    describe(`-> create`) => {
        it(`creates a request with the proper path, method, and Accept header`) => {
            protect => { #database->create }
            local(req) = #database->server->currentRequest

            expect('/name', #req->urlPath)
            expect('PUT'  , #req->method)
            expect(#req->headers >> pair(`Accept` = "application/json"))
        }
    }


    describe(`-> delete`) => {
        it(`creates a request with the proper path, method, and Accept header`) => {
            protect => { #database->delete }
            local(req) = #database->server->currentRequest

            expect('/name' , #req->urlPath)
            expect('DELETE', #req->method)
            expect(#req->headers >> pair(`Accept` = "application/json"))
        }
    }


    describe(`-> createDocument`) => {
        it(`creates a request with the proper path and method`) => {
            protect => { #database->createDocument(map("foo"="bar")) }
            local(req) = #database->server->currentRequest

            expect('/name', #req->urlPath)
            expect('POST' , #req->method)
        }

        it(`creates a request with the proper Accept and Content-Type headers`) => {
            protect => { #database->createDocument(map("foo"="bar")) }
            local(req) = #database->server->currentRequest

            expect(#req->headers >> pair(`Accept`       = "application/json"))
            expect(#req->headers >> pair(`Content-Type` = "application/json"))
        }

        it(`creates a request with a JSON request body`) => {
            protect => { #database->createDocument(map("foo"="bar")) }
            local(result) = json_decode(#database->server->currentRequest->postParams)

            //expect(map("foo"="bar"), #result)
            //maps don't compare?
            expect((:"foo"), #result->keys)
            expect((:"bar"), #result->values)
        }

        it(`creates a request with the X-Couch-Full-Commit header set to true when passed -waitForWrite`) => {
            protect => { #database->createDocument(map("foo"="bar"), -waitForWrite) }
            local(req) = #database->server->currentRequest

            expect('/name', #req->urlPath)
            expect(#req->headers >> pair(`X-Couch-Full-Commit` = "true"))
        }

        it(`creates a request with the X-Couch-Full-Commit header set to false when passed -noWaitForWrite`) => {
            protect => { #database->createDocument(map("foo"="bar"), -noWaitForWrite) }
            local(req) = #database->server->currentRequest

            expect(#req->headers >> pair(`X-Couch-Full-Commit` = "false"))
        }

        it(`fails if both -waitForWrite and -noWaitForWrite are passed at the same time`) => {
            expect->errorCode(error_code_runtimeAssertion) => {
                #database->createDocument(map("foo"="bar"), -waitForWrite, -noWaitForWrite)
            }
        }

        it(`creates a request with batch=ok in the query parameters when passed -batchMode`) => {
            protect => { #database->createDocument(map("foo"="bar"), -batchMode) }
            local(req) = #database->server->currentRequest

            expect(#req->getParams >> pair('batch', 'ok'))
        }
    }
}