define couchDB_server => type {
    data
        public protocol::string,
        public host::string,
        public port::integer,

        private currentRequest,
        private currentResponse


    public onCreate(connection::string, -noSSL::boolean=false) => {
        local(host, port) = #connection->split(':')

        .host     = #host
        .port     = (#port  ? integer(#port) | 5984   )
        .protocol = (#noSSL ? 'http'         | 'https')
    }


    public info => {
        .generateRequest(
            '/',
            -headers = (:`Accept` = "application/json")
        )

        return json_decode(.currentResponse->bodyString)
    }

    // TODO: Custom Type Result
    public activeTasks => {
        .generateRequest(
            '/_active_tasks',
            -headers = (:`Accept` = "application/json")
        )
        
        return object_map_array(json_decode(.currentResponse->bodyString), ::couchResponse_task)
    }

    public allDBs => {
        .generateRequest(
            '/_all_dbs',
            -headers = (:`Accept` = "application/json")
        )

        return json_decode(.currentResponse->bodyString)
    }

    public dbUpdates(feed::string, -timeout::integer=60, -noHeartbeat::boolean=false) => {
        (:'longpoll', 'continuous', 'eventsource') !>> #feed
            ? fail(error_code_invalidParameter, "Invalid parameter passed to feed")


        .generateRequest(
            '/_db_updates',
            -headers   = (:`Accept` = "application/json"),
            -getParams = (:`feed` = #feed, `timeout` = #timeout, `heartbeat` = not #noHeartbeat)

        )

        return json_decode(.currentResponse->bodyString)
    }

    public log(-offset::integer=0, -bytes::integer=1000) => {
        .generateRequest(
            '/_log',
            -headers   = (:`Accept` = "text/plain; charset=utf-8"),
            -getParams = (:`offset` = #offset, `bytes` = #bytes)
        )

        return .currentResponse->bodyString
    }

    public replicate(
        source::string,
        target::string,
        -createTarget::boolean = false,
        -continuous::boolean   = false,
        -cancel::boolean       = false,
        -docIDs::trait_forEach = (:),
        -proxy::string         = ''
    ) => {
        local(params) = map(`source` = #source, `target` = #target)

        #createTarget? #params->insert(`create_target` = true)
        #continuous  ? #params->insert(`continuous`    = true)
        #cancel      ? #params->insert(`cancel`        = true)
        #proxy != '' ? #params->insert(`proxy`         = #proxy)

        if(#docIDs->isNotEmpty) => {
            #docIDs->isNotA(::array) and #docIDs->isNotA(::staticarray)
                ? #docIDs = (with elm in #docIDs select #elm)->asStaticArray

            #params->insert(`doc_ids` = #docIDs)
        }

        .generateRequest(
            '/_replicate',
            -method     = `POST`,
            -headers    = (:`Accept` = "application/json", `Content-Type` = "application/json"),
            -postParams = json_encode(#params)
        )

        return couchResponse_replication(json_decode(.currentResponse->bodyString))
    }

    public restart => {
        .generateRequest(
            '/_restart',
            -method  = "POST",
            -headers = (:`Accept` = "application/json", `Content-Type` = "application/json")
        )

        return .currentResponse->statusCode == 202
    }

    public stats => {
        .generateRequest(
            '/_stats',
            -headers = (:`Accept` = "application/json")
        )
        return couchResponse_allStats(json_decode(.currentResponse->bodyString))
    }

    public stats(section::string, statistic::string) => {
        .generateRequest(
            '/_stats/' + #section + '/' + #statistic,
            -headers = (:`Accept` = "application/json")
        )
        local(result) = json_decode(.currentResponse->bodyString)->find(#section)
        #result->insert(`sectionName` = #section, `name` = #statistic)

        return couchResponse_stat(#result)
    }

    public uuid => {
        .generateRequest(
            '/_uuids',
            -headers = (:`Accept` = "application/json")
        )
        return json_decode(.currentResponse->bodyString)->find(`uuids`)->first
    }
    public uuids(count::integer) => {
        #count < 1 ? #count = 1

        .generateRequest(
            '/_uuids',
            -headers = (:`Accept` = "application/json"),
            -getParams = (:`count` = #count)
        )
        return json_decode(.currentResponse->bodyString)->find(`uuids`)
    }



    // Introspection Accessors
    public
        baseURL         => .protocol + '://' + .host + ':' + .port,
        currentRequest  => .`currentRequest`,
        currentResponse => .`currentResponse` || .makeRequest&currentResponse



    private generateRequest(path::string, ...) => {
        .currentRequest  = http_request(:(:.baseURL + #path) + (#rest || (:)))
        .currentResponse = null
    }

    private makeRequest => {
        .currentResponse = .currentRequest->response

        fail_if(.currentResponse->statusCode > 299, .currentResponse->statusCode, .currentResponse->statusMsg)
    }
}