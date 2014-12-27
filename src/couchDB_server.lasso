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
        
        return json_decode(.currentResponse->bodyString)
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

        return json_decode(.currentResponse->bodyString)
    }

    // TODO: Custom Type Result
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

        return json_decode(.currentResponse->bodyString)
    }

    public restart => {
        .generateRequest(
            '/_restart',
            -method  = "POST",
            -headers = (:`Accept` = "application/json", `Content-Type` = "application/json")
        )

        return currentResponse->statusCode == 202
    }

    // TODO: CUSTOM Type Result (and or sub results)
    public session(-basic::boolean=false) => {
        .generateRequest(
            `/_session`,
            -headers   = (:`Accept` = "application/json"),
            -getParams = (#basic ? (:`basic` = true) | (:))
        )
        return json_decode(.currentResponse->bodyString)
    }
    // TODO: CUSTOM Type Result (and or sub results)
    public sessionNew(-redirectPath::string='') => {
        .generateRequest(
            `/_session`,
            -method     = 'POST',
            -headers    = (:`Accept` = "application/json", `Content-Type` = "application/json"),
            -getParams  = (#redirectPath->isNotEmpty? (:`next` = #redirectPath) | (:)),
            -postParams = json_encode(map(`name` = .username, `password` = .password))
        )

        return json_decode(.currentResponse->bodyString)
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

        return currentResponse->statusCode == 200
    }

    // TODO: Custom Type Result (or sub results...)
    public stats => {
        .generateRequest(
            '/_stats',
            -headers = (:`Accept` = "application/json")
        )
        return json_decode(.currentResponse->bodyString)
    }
    // TODO: Custom Type Result (stick section and name into parameters as well as the sub keys?)
    public stats(section::string, statistic::string) => {
        .generateRequest(
            '/_stats/' + #section + '/' + #statistic,
            -headers = (:`Accept` = "application/json")
        )
        return json_decode(.currentResponse->bodyString)
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
        currentRequest  => .`currentRequest`,
        currentResponse => .`currentResponse` || .`currentResponse` := .currentRequest->response



    private generateRequest(path::string, ...) => {
        .currentRequest  = http_request(:(:.protocol + '://' + .host + ':' + .port + #path) + (#rest || (:)))
        .currentResponse = null
    }
}