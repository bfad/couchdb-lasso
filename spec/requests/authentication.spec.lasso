local(path_here) = currentCapture->callsite_file->stripLastComponent
not #path_here->beginsWith('/')? #path_here = io_file_getcwd + '/' + #path_here
not #path_here->endsWith('/')  ? #path_here->append('/')
not var_defined('_couch_loaded')
    ? sourcefile(file(#path_here + '../spec_helper.inc'), -autoCollect=false)->invoke

describe(`No Authentication`) => {
    local(server) = couchDB_server('bad_domain')
    protect => { #server->info }

    it(`doesn't do basic authentication`) => {
        expect('', #server->currentRequest->username)
    }

    it(`doesn't do cookie authentication`) => {
        expect(not #server->currentRequest->urlPath->beginsWith('/_session'))
        expect(#server->currentRequest->headers->find(`Cookie`)->size == 0)
    }

    it(`doesn't do proxy authentication`) => {
        expect(#server->currentRequest->headers->find(`X-Auth-CouchDB-UserName`)->size == 0)
    }

    it(`doesn't do oAuth authentication (or basic)`) => {
        expect(#server->currentRequest->headers->find('Authorization')->size == 0)
    }
}


describe(`Basic Authentication`) => {
    it(`creates a request with username for http_request`) => {
        local(server) = mock_server_basic_auth
        #server->info

        expect("tester", #server->currentRequest->username)
        expect(null    , #server->authCookie)
    }

    it(`successfully connects to _log (which requires admin privileges)`) => {
        local(server) = mock_server_basic_auth

        expect->errorCode(0) => {
            #server->log(-bytes=1)
        }
    }
}


describe(`Cookie Authentication`) => {
    context(`No stored cookie yet`) => {
        it(`successfully authenticates and stores the cookie and then returns the original request`) => {
            local(server) = mock_server_cookie_auth
            expect->null(#server->authCookie)

            expect->errorCode(0) => {
                #server->log(-bytes=1)
            }

            expect(::string, #server->authCookie->type)
        }
    }


    context(`Valid stored cookie`) => {
        local(good_cookie) = mock_server_cookie_auth->sessionNew&currentResponse->header(`Set-Cookie`)->split(';')->first
        
        it(`sets the cookie in the curl options and successfully authenticates`) => {
            local(server) = mock_server_cookie_auth
            #server->authCookie = #good_cookie

            expect->errorCode(0) => {
                #server->log(-bytes=1)
            }

            expect(#server->currentRequest->options >> pair(CURLOPT_COOKIE = #good_cookie))
        }
    }


    context(`Invalid stored cookie`) => {
        it(`re-authenticates to get an unexpired cookie`) => {
            local(server) = mock_server_cookie_auth
            #server->authCookie = 'bad cookie'

            expect->errorCode(0) => {
                #server->log(-bytes=1)
            }
            expect('bad cookie' != #server->authCookie)
        }
    }
}