local(path_here) = currentCapture->callsite_file->stripLastComponent
not #path_here->beginsWith('/')? #path_here = io_file_getcwd + '/' + #path_here
not #path_here->endsWith('/')  ? #path_here->append('/')
not var_defined('_couch_loaded')
    ? sourcefile(file(#path_here + '../spec_helper.inc'), -autoCollect=false)->invoke


local(server)      = mock_server_no_auth
local(server_auth) = mock_server_cookie_auth

describe(::couchDB_database) => {
    #server_auth->generateRequest('/test', -method="PUT")&makeRequest
    afterAll => {
        #server_auth->generateRequest('/test', -method="DELETE")&makeRequest
    }

    local(db_auth)   = couchDB_database(#server_auth, 'test')
    local(db_noauth) = couchDB_database(#server     , 'test')

    describe(`-> exists`) => {
        it(`returns true when the response is a 200`) => {
            expect(true, #db_auth->exists)
            expect(200, #db_auth->server->currentResponse->statusCode)
        }

        it(`returns false when the response is a 404`) => {
            local(db) = couchDB_database(#server_auth, 'noexists')
            expect(false, #db->exists)
            expect(404, #db->server->currentResponse->statusCode)
        }
    }


    describe(`-> info`) => {
        it(`fails when the database doesn't exist`) => {
            local(db) = couchDB_database(#server_auth, 'noexists')

            expect->errorCode(404) => {
                #db->info
            }
        }

        it(`returns a [couchResponse_databaseInfo] object and 200 response`) => {
            expect(::couchResponse_databaseInfo, #db_auth->info->type)
            expect(200                         , #db_auth->server->currentResponse->statusCode)
        }
    }
}