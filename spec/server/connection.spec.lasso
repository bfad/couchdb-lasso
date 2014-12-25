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


    local(server) = couchDB_server('bad_domain')
    describe(`-> info`) => {
        it(`creates a request with a header that specifies it expects a json response`) => {
            protect => { #server->info }

            expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
        }
    }

    describe(`-> activeTasks`) => {
        beforeAll => {
            protect => { #server->activeTasks }
        }
        it(`creates a request with the proper path`) => {
            expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
        }

        it(`creates a request with a header that specifies it expects a json response`) => {
            expect("/_active_tasks", #server->currentRequest->urlPath)
        }
    }

    describe(`-> allDBs`) => {
        beforeAll => {
            protect => { #server->allDBs }
        }
        it(`creates a request with the proper path`) => {
            expect("/_all_dbs", #server->currentRequest->urlPath)
        }

        it(`creates a request with a header that specifies it expects a json response`) => {
            expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
        }
    }

    describe(`-> dbUpdates`) => {
        it(`fails if not passed a proper feed parameter`) => {
            expect->errorCode(error_code_invalidParameter) => {
                #server->dbUpdates('_BAD_')
            }

            local(failure)  = false
            local(statuses) = (:'longpoll', 'continuous', 'eventsource')
            with status in #statuses do {
                protect => {
                    handle_error => {
                        #failure = error_code == error_code_invalidParameter
                    }
                    #server->dbUpdates(#status)
                }
                expect(not #failure)
            }
        }

        it(`creates a request with the proper path and Accept header`) => {
            protect => { #server->dbUpdates('longpoll') }

            expect("/_db_updates", #server->currentRequest->urlPath)
            expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
        }

        it(`creates a request with the specified feed parameter and proper defaults`) => {
            protect => { #server->dbUpdates('continuous') }

            expect(#server->currentRequest->getParams >> pair("feed", "continuous"))

            expect(#server->currentRequest->getParams >> pair("timeout", 60))
            expect(#server->currentRequest->getParams >> pair("heartbeat", true))
        }

        it(`creates a request with the specified timeout parameter`) => {
            protect => { #server->dbUpdates('longpoll', -timeout=5) }

            expect(#server->currentRequest->getParams >> pair("timeout", 5))
        }

        it(`creates a request with the specified heartbeat parameter`) => {
            protect => { #server->dbUpdates('longpoll', -noHeartbeat) }

            expect(#server->currentRequest->getParams >> pair("heartbeat", false))

        }
    }
}


/*
local(live) = couchDB_server('127.0.0.1', -noSSL)
it(`returns an object with some expected keys / values`) => {
    local(result) = #live->info

    expect("Welcome", #result->find(`couchdb`))
    expect->valueIsA(#result->find(`version`), ::string)
}
*/