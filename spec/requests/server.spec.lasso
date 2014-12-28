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

    describe(`-> config`) => {
        context(`with no parameters`) => {
            beforeAll => {
                protect => { #server->config }
            }
            it(`creates a request with the proper path`) => {
                expect("/_config", #server->currentRequest->urlPath)
            }

            it(`creates a request with a header that specifies it expects a json response`) => {
                expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
            }
        }

        context(`specifying the section`) => {
            beforeAll => {
                protect => { #server->config('section') }
            }
            it(`creates a request with the proper path`) => {
                expect("/_config/section", #server->currentRequest->urlPath)
            }

            it(`creates a request with a header that specifies it expects a json response`) => {
                expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
            }
        }

        context(`specifying a specific configuration option`) => {
            beforeAll => {
                protect => { #server->config('section', 'option') }
            }
            it(`creates a request with the proper path`) => {
                expect("/_config/section/option", #server->currentRequest->urlPath)
            }

            it(`creates a request with a header that specifies it expects a json response`) => {
                expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
            }
        }
    }


    describe(`-> configUpdate`) => {
        beforeAll => {
            protect => { #server->configUpdate('section', 'option', 'value') }
        }
        it(`creates a request with the proper path`) => {
            expect("/_config/section/option", #server->currentRequest->urlPath)
        }

        it(`creates a request with the proper Accept and Content-Type headers`) => {
            expect(#server->currentRequest->headers >> pair(`Accept`       = "application/json"))
            expect(#server->currentRequest->headers >> pair(`Content-Type` = "application/json"))
        }

        it(`creates a request with the PUT methd and proper request body`) => {
            expect(`PUT`    , #server->currentRequest->method)
            expect(`"value"`, #server->currentRequest->postParams)
        }
    }


    describe(`-> configDelete`) => {
        beforeAll => {
            protect => { #server->configDelete('section', 'option') }
        }
        it(`creates a request with the proper path and method`) => {
            expect("/_config/section/option", #server->currentRequest->urlPath)
            expect("DELETE"                 , #server->currentRequest->method)
        }

        it(`creates a request with the proper Accept header`) => {
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

    describe(`-> log`) => {
        it(`creates a request with the proper path and Accept header`) => {
            protect => { #server->log }

            expect("/_log", #server->currentRequest->urlPath)
            expect(#server->currentRequest->headers >> pair(`Accept` = "text/plain; charset=utf-8"))
        }

        it(`creates a request with the proper defaults`) => {
            protect => { #server->log }

            expect(#server->currentRequest->getParams >> pair("bytes", 1000))
            expect(#server->currentRequest->getParams >> pair("offset", 0))
        }

        it(`creates a request with the specified timeout parameter`) => {
            protect => { #server->log(-bytes=5) }

            expect(#server->currentRequest->getParams >> pair("bytes", 5))
        }

        it(`creates a request with the specified heartbeat parameter`) => {
            protect => { #server->log(-offset=2000) }

            expect(#server->currentRequest->getParams >> pair("offset", 2000))

        }
    }

    describe(`-> replicate`) => {
        it(`creates a request with the proper path, method, Accept header, and Content-Type header`) => {
            protect => { #server->replicate('source', 'destination') }

            expect("/_replicate", #server->currentRequest->urlPath)
            expect("POST"       , #server->currentRequest->method)
            expect(#server->currentRequest->headers >> pair(`Accept`       = "application/json"))
            expect(#server->currentRequest->headers >> pair(`Content-Type` = "application/json"))
        }

        it(`properly creates a JSON object with the source and destination specified in the post body`) => {
            protect => { #server->replicate('source', 'target') }

            local(body) = json_decode(#server->currentRequest->postParams)
            expect('source', #body->find(`source`))
            expect('target', #body->find(`target`))
        }

        it(`it adds the create_target option only when it's true`) => {
            protect => { #server->replicate('source', 'destination') }

            expect(void, json_decode(decode_url(#server->currentRequest->postParams)->asString)->find(`create_target`))

            protect => { #server->replicate('source', 'destination', -createTarget) }

            expect(true, json_decode(decode_url(#server->currentRequest->postParams)->asString)->find(`create_target`))
        }

        it(`it adds the continuous option only when it's true`) => {
            protect => { #server->replicate('source', 'destination') }

            expect(void, json_decode(decode_url(#server->currentRequest->postParams)->asString)->find(`continuous`))

            protect => { #server->replicate('source', 'destination', -continuous) }

            expect(true, json_decode(decode_url(#server->currentRequest->postParams)->asString)->find(`continuous`))
        }

        it(`it adds the cancel option only when it's true`) => {
            protect => { #server->replicate('source', 'destination') }

            expect(void, json_decode(decode_url(#server->currentRequest->postParams)->asString)->find(`cancel`))

            protect => { #server->replicate('source', 'destination', -cancel) }

            expect(true, json_decode(decode_url(#server->currentRequest->postParams)->asString)->find(`cancel`))
        }

        it(`it adds the doc_ids option only when it's true`) => {
            protect => { #server->replicate('source', 'destination') }

            expect(void, json_decode(decode_url(#server->currentRequest->postParams)->asString)->find(`doc_ids`))

            local(ids) = array(lasso_uniqueID)
            protect => { #server->replicate('source', 'destination', -docIDs=#ids) }

            expect(#ids, json_decode(decode_url(#server->currentRequest->postParams)->asString)->find(`doc_ids`))
        }

        it(`it adds the proxy option only when it's true`) => {
            protect => { #server->replicate('source', 'destination') }

            expect(void, json_decode(decode_url(#server->currentRequest->postParams)->asString)->find(`proxy`))

            local(proxy) = "socks5://example.com"
            protect => { #server->replicate('source', 'destination', -proxy=#proxy) }

            expect(#proxy, json_decode(decode_url(#server->currentRequest->postParams)->asString)->find(`proxy`))
        }
    }


    describe(`-> restart`) => {
        it(`creates a request with the proper path and method`) => {
            protect => { #server->restart }

            expect("/_restart", #server->currentRequest->urlPath)
            expect("POST"     , #server->currentRequest->method)
        }

        it(`creates a request with the proper Accept and Content-Type headers`) => {
            protect => { #server->restart }

            expect(#server->currentRequest->headers >> pair(`Accept`       = "application/json"))
            expect(#server->currentRequest->headers >> pair(`Content-Type` = "application/json"))
        }
    }


    describe(`-> session`) => {
        it(`creates a request with the proper path and Accept header`) => {
            protect => { #server->session }

            expect("/_session", #server->currentRequest->urlPath)
            expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
        }

        it(`creates a request with the query parameter basic=true when basic is specified`) => {
            protect => { #server->session(-basic) }

            expect(#server->currentRequest->getParams >> pair("basic", true))
        }
    }

    describe(`-> sessionNew`) => {
        it(`creates a request with the proper path and method`) => {
            protect => { #server->sessionNew }

            expect("/_session", #server->currentRequest->urlPath)
            expect("POST"     , #server->currentRequest->method)
        }

        it(`creates a request with the proper Accept and Content-Type headers`) => {
            protect => { #server->sessionNew }

            expect(#server->currentRequest->headers >> pair(`Accept`       = "application/json"))
            expect(#server->currentRequest->headers >> pair(`Content-Type` = "application/json"))
        }

        it(`creates a request with a JSON body with the stored username and password`) => {
            #server->username = "marty"
            #server->password = "McFly"

            protect => { #server->sessionNew }
            local(request_body) = json_decode(#server->currentRequest->postParams)

            expect("marty", #request_body->find(`name`))
            expect("McFly", #request_body->find(`password`))
        }

        it(`sets up the next query param if redirectPath specified`) => {
            protect => { #server->sessionNew(-redirectPath="/") }

            expect(#server->currentRequest->getParams >> pair("next", "/"))
        }

        it(`takes a username and password parameters to set the username and password to use for authentication`) => {
            protect => { #server->sessionNew("doc", "Brown") }
            local(request_body) = json_decode(#server->currentRequest->postParams)

            expect("doc", #server->username)
            expect("doc", #request_body->find(`name`))

            expect("Brown", #server->password)
            expect("Brown", #request_body->find(`password`))
        }

        it(`allows for specifying the redirectPath when also specifying user and password`) => {
            protect => { #server->sessionNew("doc", "Brown", -redirectPath="/_log") }

            expect(#server->currentRequest->getParams >> pair("next", "/_log"))
        }
    }

    describe(`-> sessionDelete`) => {
        it(`creates a request with the proper path, method, and Accept header`) => {
            protect => { #server->sessionDelete }

            expect("/_session", #server->currentRequest->urlPath)
            expect("DELETE"   , #server->currentRequest->method)
            expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
        }
    }


    describe(`-> stats`) => {
        it(`creates a request with the proper path`) => {
            protect => { #server->stats }

            expect("/_stats", #server->currentRequest->urlPath)
        }

        it(`creates a request with the proper Accept header`) => {
            protect => { #server->stats }

            expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
        }

        it(`creates a request with the proper path when an individual statistic is requested`) => {
            protect => { #server->stats('couchdb', 'request_time') }

            expect("/_stats/couchdb/request_time", #server->currentRequest->urlPath)
            expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
        }
    }


    describe(`-> uuid`) => {
        it(`creates a request with the proper path and Accept header`) => {
            protect => { #server->uuid }

            expect("/_uuids", #server->currentRequest->urlPath)
            expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
        }
    }
    describe(`-> uuids`) => {
        it(`creates a request with the proper path and Accept header`) => {
            protect => { #server->uuids(10) }

            expect("/_uuids", #server->currentRequest->urlPath)
            expect(#server->currentRequest->headers >> pair(`Accept` = "application/json"))
        }

        it(`creates a request with the specified count parameter`) => {
            protect => { #server->uuids(42) }

            expect(#server->currentRequest->getParams >> pair("count", 42))
        }

        it(`creates a request with the count specified as 1 if passed a number < 1`) => {
            protect => { #server->uuids(0) }

            expect(#server->currentRequest->getParams >> pair("count", 1))
        }
    }
}
