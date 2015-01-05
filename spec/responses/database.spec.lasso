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


    describe(`-> createDocument`) => {
        // Need to figure out how to not allow public writers before this test will pass
        //it(`fails when not logged in as an admin`) => {
        //    expect->errorCode(401) => {
        //        #db_noauth->createDocument(map("foo"="bar"))
        //    }
        //}

        it(`fails if trying to create a document in a database that doesn't already exist`) => {
            local(db) = couchDB_database(#server_auth, 'noexists')
            
            expect->errorCode(404) => {
                #db->createDocument(map("foo"="bar"))
            }
        }

        it(`fails if the database name uses restricted characters`) => {
            local(db) = couchDB_database(#server_auth, 'bad chars!')

            expect->errorCode(400) => {
                #db->createDocument(map("foo"="bar"))
            }
        }

        it(`returns a map with the id and revision number, and a 201 response`) => {
            local(result) = #db_auth->createDocument(map("foo"="bar"))

            expect(201     , #db_auth->server->currentResponse->statusCode)
            expect(::string, #result->find(`id`)->type)
            expect(::string, #result->find(`rev`)->type)
        }

        it(`returns a map with an id and has 202 response`) => {
            local(result) = #db_auth->createDocument(map("foo"="bar"), -batchMode)

            expect(202     , #db_auth->server->currentResponse->statusCode)
            expect(::string, #result->find(`id`)->type)
        }
    }


    describe(`-> allDocuments`) => {
        // Need to figure out how to not allow public readers before this test will pass
        //it(`fails when not logged in as an admin`) => {
        //    expect->errorCode(401) => {
        //        #db_noauth->allDocuments
        //    }
        //}

        it(`fails if tyring to access documents in a database that doesn't exist`) => {
            local(db) = couchDB_database(#server_auth, 'noexists')
            
            expect->errorCode(404) => {
                #db->allDocuments
            }
        }

        it(`returns a [couchResponse_allDocuments] object with a 200 response`) => {
            expect(::couchResponse_allDocuments, #db_auth->allDocuments->type)
            expect(200                         , #db_auth->server->currentResponse->statusCode)
        }

        it(`has every element in returned [couchResponse_allDocuments->rows] be a [couchResponse_documentMetaData]`) => {
            #db_auth->createDocument(map("key"="value"))
            local(rows) = #db_auth->allDocuments->rows

            expect(#rows->size > 0)
            with row in #rows do expect(::couchResponse_documentMetaData, #row->type)
        }

        context(`specifying multiple keys`) => {
            it(`only returns documents with the specified keys`) => {
                local(doc1) = #db_auth->createDocument(map(`doc1` = 1))
                local(doc2) = #db_auth->createDocument(map(`doc2` = 2))
                local(doc3) = #db_auth->createDocument(map(`doc3` = 3))
                local(keys) = (:#doc1->find(`id`), #doc3->find(`id`))
                local(rows) = #db_auth->allDocuments(-keys=#keys)->rows

                expect(2, #rows->size)
            }
        }
    }


    describe(`-> bulkActionDocuments`) => {
        // Need to figure out how to not allow public readers before this test will pass
        //it(`fails when not logged in as an admin`) => {
        //    expect->errorCode(401) => {
        //        #db_noauth->bulkActionDocuments((: map("foo"="bar")))
        //    }
        //}

        it(`fails if trying to create a document in a database that doesn't already exist`) => {
            local(db) = couchDB_database(#server_auth, 'noexists')
            
            expect->errorCode(404) => {
                #db->bulkActionDocuments((:map("foo"="bar")))
            }
        }

        it(`returns on array of maps for the created, deleted, or updated elements`) => {
            local(result) = #db_auth->bulkActionDocuments((:map("foo"="bar")))

            expect(::array, #result->type)
            expect(1      , #result->size)
            expect(201    , #db_auth->server->currentResponse->statusCode)
        }

        // TODO: Figure out how to check this test
        //context(`When transaction mode set to all-or-nothing`) => {
        //    it(`fails when a document fails to validate`) => {
        //        expect->errorCode(417) => {}
        //    }
        //}
    }
}