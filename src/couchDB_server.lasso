define couchDB_server => type {
    data
        public protocol::string,
        public host::string,
        public port::integer,
        public username::string,
        public password::string,
        public authCookie,

        private currentRequest,
        private currentResponse,
        private authType::string


    public onCreate(
        connection::string,
        -noSSL::boolean=false,
        -username::string='',
        -password::string='',
        -basicAuth::boolean=false
    ) => {
        local(host, port) = #connection->split(':')

        .host       = #host
        .port       = (#port  ? integer(#port) | 5984   )
        .protocol   = (#noSSL ? 'http'         | 'https')
        .username   = #username
        .password   = #password
        .authCookie = null

        #username == ''
            ? .authType = 'none'
            | .authType = (#basicAuth ? 'basic' | 'cookie')
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

    public config(section::string='', option::string='') => {
        local(path) = '/_config'

        if(#section->isNotEmpty) => {
            #path->append('/' + #section)

            #option->isNotEmpty
                ? #path->append('/' + #option)
        }

        .generateRequest(
            #path,
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

    public session(-basic::boolean=false) => {
        .generateRequest(
            `/_session`,
            -headers   = (:`Accept` = "application/json"),
            -getParams = (#basic ? (:`basic` = true) | (:))
        )
        local(result) = json_decode(.currentResponse->bodyString)
        local(value)  = #result->find(`info`)
        #value->insert(`userCtx`=#result->find(`userCtx`))

        return couchResponse_session(#value)
    }

    public sessionNew(-redirectPath::string='') => {
        .generateRequest(
            `/_session`,
            -method     = 'POST',
            -headers    = (:`Accept` = "application/json", `Content-Type` = "application/json"),
            -getParams  = (#redirectPath->isNotEmpty? (:`next` = #redirectPath) | (:)),
            -postParams = json_encode(map(`name` = .username, `password` = .password))
        )

        return (json_decode(.currentResponse->bodyString)->insert(`cookie`=.currentResponse->header(`Set-Cookie`))&)
    }
    public sessionNew(username::string, password::string, -redirectPath::string = '') => {
        .username = #username
        .password = #password

        return .sessionNew(-redirectPath=#redirectPath)
    }
    
    public sessionDelete => {
        .generateRequest(
            `/_session`,
            -method  = "DELETE",
            -headers = (:`Accept` = "application/json")
        )

        return .currentResponse->statusCode == 200
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
        .currentResponse = null
        .currentRequest  = http_request(:(:.baseURL + #path) + (#rest || (:)))

        // If posting to /_session, trying to get a new Authentication token, so don't setup auth
        #path == "/_session" and .currentRequest->method == "POST"
            ? null
            | .setupAuthentication
    }
    private setupAuthentication => {
        match(.authType) => {
        case('basic')
            .currentRequest->username      = .username
            .currentRequest->password      = .password
            .currentRequest->basicAuthOnly = true

        case('cookie')
            not .authCookie ? .getAuthCookie

            .currentRequest->options = (:CURLOPT_COOKIE = .authCookie)
        }
    }

    private makeRequest(count::integer=1) => {
        // Force a new request to be evaluated each time
        // This is especially needed when re-authenticating
        .currentResponse   = .currentRequest->makeRequest&response
        local(status_code) = .currentResponse->statusCode

        if(#status_code == 401 and #count == 1 and .authType == 'cookie') => {
            .getAuthCookie
            .setupAuthentication
            return .makeRequest(2)

        else(#status_code > 399)
            fail(#status_code, .currentResponse->statusMsg)
        }
    }

    private getAuthCookie => {
        local(auth_req) = self->asCopy
        #auth_req->sessionNew

        .authCookie = #auth_req->currentResponse->header(`Set-Cookie`)->split(';')->first
    }
}