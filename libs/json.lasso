define json_open_object => 123
define json_open_array => 91
define json_close_object => 125
define json_close_array => 93
define json_quote_double => 34
define json_white_space => 32
define json_colon => 58
define json_comma => 44
define json_back_slash => 92
define json_forward_slash => 47
define json_negative => 45
define json_period => 46
define json_e_upper => 69
define json_e_lower => 101

define json_back_space => 8
define json_form_feed => 12

define json_f_lower => 102
define json_t_lower => 116
define json_n_lower => 110

define json_lf => 10
define json_cr => 13
define json_tab => 9

define json_debug(s) => stdoutnl(#s)

define json_decode => type {

    data private stack
    data private exit
    
    public onCreate(s::string) => {
        #s->size == 0?
            return void
        local(stack = array,
            result = .deserialize(#s, 1, #s->size, #stack))
        #stack->size != 0?
            fail('Unterminated JSON object: ' + #stack)
        return #result // return something not self
    }
    
    protected handlePop() => .handlePop(.stack->pop)
    
    protected handlePop(obj) => {
        .stack->size > 0?
            return .handleNested(.stack->top, #obj)
        .exit = #obj
        return #obj
    }
    
    protected handleNested(top::pair, obj) => { 
        #top->second = #obj 
        return .handleNested(.stack->pop&top, #top)
    }
    protected handleNested(top::map, obj::pair) => #top->insert(#obj->first = #obj->second)
    protected handleNested(top::map, obj) => { .stack->push(pair(#obj, void)) }
    protected handleNested(top::array, obj) => #top->insert(#obj)
    protected handleNested(errorObj, obj) => fail('')
    
    protected readString(src::string, start::integer) => {
        local(esc = false)
        
        // #start is pointing at opening quote
        #start += 1
        
        local(subStart = #start)
        
        local(char)
        {
            #char = #src->integer(#start)       
            #start += 1
            #char == json_quote_double and not #esc?
                returnHome
            
            #char == json_back_slash?
                #esc = !#esc                    
                
            currentCapture->restart
        }()
        
        local(sub = #src->sub(#subStart, #start - #subStart - 1)->unescape)
        
        return (:#sub, #start - 1)
    }
    
    protected readNumber(src::string, start::integer) => {

        local(subStart = #start)
        
        #src->integer(#start) == json_negative?
            #start += 1
        
        local(needPeriod = true, needExp = true, inNumber = true)
        while(#inNumber) => {
            local(char = #src->integer(#start))
            match(true) => {
                case(#src->isDigit(#start))
                    ;
                case(#needPeriod and #char == json_period)
                    #needPeriod = false
                    
                case(#needExp and (#char == json_e_upper or #char == json_e_lower))
                    #needExp = false
                    #needPeriod = false
                    
                case
                    #inNumber = false
            }
            #start += 1
        }
        
        local(sub = #src->sub(#subStart, #start - #subStart - 1))
        
        #needExp and #needPeriod?
            return (:integer(#sub), #start-2)
        
        return (:decimal(#sub), #start-2)
    }
    
    public deserialize(s::string, 
                    start::integer, 
                    end::integer, 
                    stack::array) => {
        .stack = #stack
        .exit = null
        
        local(top, char)
        
        {// main loop   
            
            #start > #end?
                return .exit or #stack->top
            #char = #s->integer(#start)     
            
            match(#char) => {
                    
                case(json_open_object)
                    //json_debug('json_open_object')
                    #stack->push(map)
                    
                case(json_open_array)
                    //json_debug('json_open_array')
                    #stack->push(array)
                
                case(json_close_object)
                    //json_debug('json_close_object')
                    .handlePop()
                    
                case(json_close_array)
                    //json_debug('json_close_array')
                    .handlePop()
                
                case(json_colon)
                    //json_debug('json_colon')
                    // valid inside a map. top object must be a pair
                    not #stack->top->isa(::pair)?
                        fail(-1, 'Invalid colon location at ' + #start + ' ' + #stack)
                    // do nothing
                    
                case(json_comma)
                    //json_debug('json_comma')
                    #stack->top->isa(::pair)?
                        fail(-1, 'Invalid comma location at ' + #start + ' ' + #stack)
                    
                case(json_quote_double) // start new string
                    //json_debug('json_quote_double')
                    local(newS, start) = .readString(#s, #start)
                    
                    .handlePop(#newS)
                
                case(json_white_space, json_lf, json_cr)
                    // inter-element white space. ignored
                    //json_debug('json_white_space')
                    
                case// number, true, false, null
                    
                    if (#char == json_negative or #s->isDigit(#start)) => {
                        //json_debug('json_number')
                        local(newS, start) = .readNumber(#s, #start)
                        .handlePop(#newS)
                        
                    else(#char == json_t_lower)
                        #s->sub(#start, 4) != 'true'?
                            fail(-1, 'Invalid character at location ' + #start + ' ' + #stack)
                        #start += 3 
                        .handlePop(true)
                        
                    else(#char == json_f_lower)
                        #s->sub(#start, 5) != 'false'?
                            fail(-1, 'Invalid character at location ' + #start + ' ' + #stack)
                        #start += 4 
                        .handlePop(false)
                        
                    else(#char == json_n_lower)
                        #s->sub(#start, 4) != 'null'?
                            fail(-1, 'Invalid character at location ' + #start + ' ' + #stack)
                        #start += 4 
                        .handlePop(null)
                        
                    else
                        stdoutnl('Unknown char: ' + #char)
                        
                    }
            }
            #start += 1
            currentCapture->restart
        }()
    }
}



define json_encode => type {
    data private s
    data private pretty // vs. compact
    
    public onCreate(value, pretty = false) => {
        .s = ''
        .pretty = #pretty
        .encodeValue(#value)
        return .s
    }
    
    protected appendComma() => {
        .pretty?
            .s->append(', ')
            | .s->append(',')
    }
    
    protected appendColon() => {
        .pretty?
            .s->append(' : ')
            | .s->append(':')
    }
    
    protected encodeValue(a::trait_finiteForEach) => {
        .s->append('[')
        local(c = 0)
        
        with e in #a
        do {
            #c?
                .appendComma
                | #c = 1
            .encodeValue(#e)
        }
        
        .s->append(']')
    }
    
    protected encodeValue(a::map) => {
        .s->append('{')
        local(c = 0)
        
        with e in #a->eachPair
        do {
            #c?
                .appendComma()
                | #c = 1
            .encodeValue(#e->first->asString)
            .appendColon
            .encodeValue(#e->second)
        }
        
        .s->append('}')
    }
    
    protected encodeValue(i::integer) => {
        .s->append(#i->asString)
    }
    
    protected encodeValue(d::decimal) => {
        .s->append(#d->asString)
    }
    
    protected encodeValue(s::string) => {
        .s->append('"')
        
        with c in 1 to #s->size
        let i = #s->integer(#c)
        do {
            match(#i) => {
                case(json_back_slash)
                    .s->append(`\\`)
                case(json_quote_double)
                    .s->append(`\"`)
                case(json_back_space)
                    .s->append(`\b`)
                case(json_form_feed)
                    .s->append(`\f`)
                case(json_lf)
                    .s->append(`\n`)
                case(json_cr)
                    .s->append(`\r`)
                case(json_tab)
                    .s->append(`\t`)
                case
                    .s->appendChar(#i)  
            }
        }
        
        .s->append('"')
    }
    
    protected encodeValue(b::boolean) => {
        .s->append(#b? 'true' | 'false')
    }
    
    protected encodeValue(n::null) => {
        .s->append('null')
    }
    
    protected encodeValue(o) => {
        .encodeValue(#o->asString)
    }
}