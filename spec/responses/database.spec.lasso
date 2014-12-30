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


    describe(`-> create`) => {
        it(`fails when not logged in as an admin`) => {
            expect->errorCode(401) => {
                #db_noauth->create
            }
        }

        it(`fails if trying to create a database that already exists`) => {
            expect->errorCode(412) => {
                #db_auth->create
            }
        }

        it(`fails if the database name uses restricted characters`) => {
            local(db) = couchDB_database(#server_auth, 'bad chars!')

            expect->errorCode(400) => {
                #db->create
            }
        }

        it(`has a 201 response and creates the database`) => {
            handle => {#server_auth->generateRequest('/new_db', -method="DELETE")&makeRequest}

            local(db) = couchDB_database(#server_auth, 'new_db')
            #db->create

            expect(201, #db->server->currentResponse->statusCode)
            expect(#db->exists)
        }
    }


    describe(`-> delete`) => {
        it(`fails when not logged in as an admin`) => {
            expect->errorCode(401) => {
                #db_noauth->delete
            }
        }

        it(`fails if trying to delete a database that doesn't already exist`) => {
            local(db) = couchDB_database(#server_auth, 'noexists')
            
            expect->errorCode(404) => {
                #db->delete
            }
        }

        it(`fails if the database name uses restricted characters`) => {
            local(db) = couchDB_database(#server_auth, 'bad chars!')

            expect->errorCode(400) => {
                #db->delete
            }
        }

        it(`has a 200 response and deletes the database`) => {
            local(db) = couchDB_database(#server_auth, 'new_db')
            #db->create
            expect(#db->exists)

            #db->delete
            expect(200, #db->server->currentResponse->statusCode)
            expect(not #db->exists)
        }
    }
}