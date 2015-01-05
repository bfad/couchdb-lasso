define couchDB_database => type {
    data
        public name,
        private server

    public onCreate(server::couchDB_server, name::string) => {
        #server = #server->asCopy

        #server->clearRequest

        .server = #server
        .name   = #name
    }


    public
        server   => .`server`,
        basePath => '/' + .name->encodeUrl


    public exists => {
        .server->generateRequest(
            .basePath,
            -method = "HEAD"
        )
        // Because 404 errors are expected (maybe turn this into try so other errors fall through?)
        protect => { .server->makeRequest }

        return .server->currentResponse->statusCode == 200
    }

    public info => {
        .server->generateRequest(
            .basePath,
            -headers = (:`Accept` = "application/json")
        )

        return couchResponse_databaseInfo(json_decode(.server->currentResponse->bodyString))
    }

    public create => {
        .server->generateRequest(
            .basePath,
            -method  = "PUT",
            -headers = (:`Accept` = "application/json")
        )

        .server->currentResponse
    }

    public delete => {
        .server->generateRequest(
            .basePath,
            -method  = "DELETE",
            -headers = (:`Accept` = "application/json")
        )

        .server->currentResponse
    }

    public createDocument(
        data::map,
        -waitForWrite::boolean=false,
        -noWaitForWrite::boolean=false,
        -batchMode::boolean=false
    ) => {
        local(headers)      = array(`Accept` = "application/json", `Content-Type` = "application/json")
        local(query_params) = array

        #waitForWrite and #noWaitForWrite
            ? fail("It is a contradiction to specify to both wait and not wait for writes")
        #waitForWrite
            ? #headers->insert(`X-Couch-Full-Commit` = "true")
        #noWaitForWrite
            ? #headers->insert(`X-Couch-Full-Commit` = "false")

        #batchMode
            ? #query_params->insert(`batch`='ok')

        .server->generateRequest(
            .basePath,
            -method     = "POST",
            -headers    = #headers,
            -getParams  = #query_params,
            -postParams = json_encode(#data)
        )

        return json_decode(.server->currentResponse->bodyString)
    }

    public allDocuments(
        -includeConflicts::boolean=false,
        -descending::boolean=false,
        -endKey::string='',
        -endKeyDocumentID::string='',
        -includeData::boolean=false,
        -inclusiveEnd::boolean=false,
        -key::string='',
        -keys::trait_finiteForEach=(:),
        -limit::integer=-1,
        -skip::integer=-1,
        -stale::string='',
        -startKey::string='',
        -startKeyDocumentID::string='',
        -includeUpdateSequence::boolean=false
    ) => {
        local(method)       = ''
        local(query_params) = array
        local(postParams) 

        #limit != -1
            ? #query_params->insert(`limit` = #limit)

        #skip != -1
            ? #query_params->insert(`skip` = #skip)


        #includeConflicts
            ? #query_params->insert(`conflicts` = true)

        #descending
            ? #query_params->insert(`descending` = true)

        #includeData
            ? #query_params->insert(`include_docs` = true)

        #inclusiveEnd
            ? #query_params->insert(`inclusive_end` = true)

        #includeUpdateSequence
            ? #query_params->insert(`update_seq` = true)


        #endKey->isNotEmpty
            ? #query_params->insert(`endkey` = #endKey)

        #endKeyDocumentID->isNotEmpty
            ? #query_params->insert(`endkey_docid` = #endKeyDocumentID)

        #key->isNotEmpty
            ? #query_params->insert(`key` = #key)

        #stale->isNotEmpty
            ? #query_params->insert(`stale` = #stale)

        #startKey->isNotEmpty
            ? #query_params->insert(`startkey` = #startKey)

        #startKeyDocumentID->isNotEmpty
            ? #query_params->insert(`startkey_docid` = #startKeyDocumentID)

        if(#keys->isNotEmpty) => {
            (: ::array, ::staticarray) !>> #keys->type
                ? #keys = (with key in #keys select #key)->asStaticarray

            #method     = `POST`
            #postParams = json_encode(map(`keys`=#keys))
        }


        .server->generateRequest(
            .basePath + '/_all_docs',
            -method     = #method,
            -headers    = (:`Accept` = "application/json"),
            -getParams  = #query_params,
            -postParams = #postParams
        )

        return couchResponse_allDocuments(json_decode(.server->currentResponse->bodyString))
    }

    public bulkActionDocuments(
        data::trait_finiteForEach,
        -waitForWrite::boolean=false,
        -noWaitForWrite::boolean=false,
        -allOrNothing::boolean=false,
        -preventNewRevision::boolean=false
    ) => {
        (: ::array, ::staticarray) !>> #data->type
            ? #data = (with datum in #data select #datum)->asStaticarray

        local(headers) = array(`Accept` = "application/json", `Content-Type` = "application/json")
        local(body)    = map("docs"=#data)

        #waitForWrite and #noWaitForWrite
            ? fail("It is a contradiction to specify to both wait and not wait for writes")
        #waitForWrite
            ? #headers->insert(`X-Couch-Full-Commit` = "true")
        #noWaitForWrite
            ? #headers->insert(`X-Couch-Full-Commit` = "false")

        #allOrNothing
            ? #body->insert(`all_or_nothing` = true)
        #preventNewRevision
            ? #body->insert(`new_edits` = false)

        


        .server->generateRequest(
            .basePath + '/_bulk_docs',
            -method     = "POST",
            -headers    = #headers,
            -postParams = json_encode(#body)
        )
        
        return json_decode(.server->currentResponse->bodyString)
    }
}