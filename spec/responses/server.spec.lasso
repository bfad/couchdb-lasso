local(path_here) = currentCapture->callsite_file->stripLastComponent
not #path_here->beginsWith('/')? #path_here = io_file_getcwd + '/' + #path_here
not #path_here->endsWith('/')  ? #path_here->append('/')
not var_defined('_couch_loaded')
    ? sourcefile(file(#path_here + '../spec_helper.inc'), -autoCollect=false)->invoke


local(server)      = mock_server_no_auth
local(server_auth) = mock_server_cookie_auth

describe(::couchDB_server) => {
    describe(`-> info`) => {
        it(`returns a map with some expected keys / values`) => {
            local(result) = #server->info

            expect("Welcome", #result->find(`couchdb`))
            expect->valueIsA(#result->find(`version`), ::string)
        }
    }


    describe(`-> activeTasks`) => {
        it(`fails when requested by a non-admin`) => {
            expect->errorCode(401) => {
                #server->activeTasks
            }
        }

        it(`returns an array of [couchResponse_task]s`) => {
            local(tasks) = #server_auth->activeTasks

            expect(boolean(#tasks->isA(::trait_forEach)))

            // Not sure how to guarantee that a task is running....
            //expect(#tasks->isNotEmpty)
            //
            //with task in #tasks do {
            //    expect(::couchResponse_task, #task->type)
            //}
        }
    }


    describe(`-> allDBs`) => {
        it(`returns an array of database names`) => {
            local(dbs) = #server->allDBs

            expect(::array, #dbs->type)
            expect(2      , #dbs->size)
        }
    }


    describe(`-> dbUpdates`) => {
        it(`fails when requested by a non-admin`) => {
            expect->errorCode(401) => {
                #server->dbUpdates('longpoll')
            }
        }

        it(`returns a map of event data`) => {
            handle => {
                // Get an http_request with proper authorization setup
                local(req)    = #server_auth->info&currentRequest
                #req->urlPath = '/db_update'
                #req->method  = 'DELETE'
                #req->makeRequest&response
            }

            local(_,reader) = split_thread => {
                local(writer) = #1->first
                #writer->writeObject("go")
                protect => {
                    handle_error => {#writer->writeObject("ERROR: " + error_msg)}
                    #writer->writeObject(#server_auth->dbUpdates('longpoll', -timeout=5000))
                }
            }
            // In an effort to guarentee the dbUpdate poll starts first, wait for the first
            // write and sleep 10ms
            local(_) = #reader->readObject
            sleep(20)

            local(req)    = #server_auth->info&currentRequest
            #req->urlPath = '/db_update'
            #req->method  = 'PUT'
            local(create) = #req->makeRequest&response
            local(result) = #reader->readObject

            expect(201  , #create->statusCode)
            expect(::map, #result->type)
        }
    }


    describe(`-> log`) => {
        it(`fails when requested by a non-admin`) => {
            expect->errorCode(401) => {
                #server->log
            }
        }

        it(`get's a string of the tail of the log`) => {
            // Generate some log data
            expect(200, http_request(#server_auth->baseURL + '/')->response->statusCode)

            local(result) = #server_auth->log(-bytes=10)

            expect(::string, #result->type)
            expect(10      , #result->size)
        }
    }


    describe(`-> replicate`) => {
        beforeAll => {
            // Get an http_request with proper authorization setup
            local(req)    = #server_auth->info&currentRequest
            #req->urlPath = '/a'
            #req->method  = 'PUT'
            #req->makeRequest&response

            #req->urlPath = '/b'
            #req->makeRequest&response
        }

        afterAll => {
            // Get an http_request with proper authorization setup
            local(req)    = #server_auth->info&currentRequest
            #req->urlPath = '/a'
            #req->method  = 'DELETE'
            #req->makeRequest&response

            #req->urlPath = '/b'
            #req->makeRequest&response
        }

        // Actually, despite docs, it allows non admins to replicate
        //it(`fails when requested by a non-admin`) => {
        //    expect->errorCode(401) => {
        //        #server->replicate('a', 'b')
        //    }
        //}

        it(`fails when either the source or target is not found`) => {
            // Docs say 404, but actual behavior is 500

            //expect->errorCode(404) => {
            expect->errorCode(500) => {
                #server_auth->replicate('a', 'z')
            }

            //expect->errorCode(404) => {
            expect->errorCode(500) => {
                #server_auth->replicate('z', 'b')
            }
        }

        it(`fails when JSON specificaiton is invalid`) => {
            expect->errorCode(500) => {
                #server_auth->replicate('a', 'b', -proxy='hah')
            }
        }

        it(`fails when trying to cancel continuous replication that doesn't exist`) => {
            expect->errorCode(404) => {
                #server_auth->replicate('a', 'b', -continuous, -cancel)
            }
        }

        it(`returns a [couchResponse_replication] object whose "history" member method returns an array of [couchResponse_replicationHistory] objects`) => {
            // Get an http_request with proper authorization setup
            // So we can stick some data up to replicate
            local(req)       = #server_auth->info&currentRequest
            #req->urlPath    = '/a/' + lasso_uniqueID
            #req->postParams = `{"foo": "bar"}`
            #req->method     = 'PUT'
            #req->makeRequest&response

            local(result) = #server_auth->replicate('a', 'b')

            expect(::couchResponse_replication, #result->type)
            expect(#result->history->isNotEmpty)
            with elm in #result->history do expect(::couchResponse_replicationHistory, #elm->type)
        }

        it(`returns a 202 response code when starting continuous replication`) => {
            #server_auth->replicate('a', 'b', -continuous)

            expect(202, #server_auth->currentResponse->statusCode)
        }
        it(`successfully cancels the continuous replication started in previous test returning 200 response code`) => {
            #server_auth->replicate('a', 'b', -continuous, -cancel)

            expect(200, #server_auth->currentResponse->statusCode)
        }
    }


    describe(`-> restart`) => {
        it(`fails when requested by a non-admin`) => {
            expect->errorCode(401) => {
                #server->restart
            }
        }

        it(`returns true and the status code is 202`) => {
            expect(#server_auth->restart)
            expect(202, #server_auth->currentResponse->statusCode)

            // wait for the server to come back
            local(stop) = true
            sleep(100)
            loop(50) => {
                protect => {
                    handle_error => {
                        sleep(100)
                        error_code == 7
                            ? #stop = false
                    }
                    #server_auth->info
                }
                #stop ? loop_abort
            }
        }
    }


    describe(`-> stats`) => {
        it(`returns a couchResponse_allStats object when called with no parameters`) => {
            expect(::couchResponse_allStats, #server->stats->type)
        }

        it(`returns a couchResponse_stat object when a statistic is specified`) => {
            expect(::couchResponse_stat, #server->stats('couchdb', 'request_time')->type)
        }

        it(`returns a couchResponse_stat object with name and sectionName filled in`) => {
            local(result) = #server->stats('httpd', 'requests')

            expect('httpd'   , #result->sectionName)
            expect('requests', #result->name)
        }
    }


    describe(`-> uuid`) => {
        it(`returns a UUID string`) => {
            local(result) = #server->uuid

            expect(::string, #result->type)
            expect(32      , #result->size)
        }
    }


    describe(`-> uuids`) => {
        it(`fails if requesting too many UUIDs`) => {
            expect->errorCode(403) => {
                #server->uuids(100000000)
            }
        }

        it(`returns an array with the specified number of UUIDs generated`) => {
            local(result) = #server->uuids(3)

            expect(::array, #result->type)
            expect(3      , #result->size)

            with elm in #result do {
                expect(::string, #elm->type)
                expect(32      , #elm->size)
            }
        }
    }    
}