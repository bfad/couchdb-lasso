// This is my workaround for the curl type's issue with HEAD requests
protect => {\curl}
define curl->headerBytes        => .`headerBytes`
define curl->bodyBytes          => .`bodyBytes`
define curl->public_performOnce => .performOnce

define get_head_response(request::http_request) => {
    #request->makeRequest
    local(curl) = #request->curl
    #curl->public_performOnce
    
    return http_response((:true, #curl->headerBytes, #curl->bodyBytes))
}