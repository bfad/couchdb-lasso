define couchResponse => type {
    data protected find

    public onCreate() => {
        .onCreate(map)
    }
    public onCreate(data::map) => {
        .find = #data
    }
    public onCreate(item::pair, ...) => {
        not .find
            ? .onCreate

        self->\(tag(#item->first + '='))->invoke(#item->second)

        #rest == void ? return

        with item in #rest
        where #item->isA(::pair)
        do self->\(tag(#item->first + '='))->invoke(#item->second)
    }

    public find(key::tag)    => .find(#key->asString)
    public find(key::string) => .find->find(#key)

    public find(update::pair)       => .find->insert(#update)
    public find(key::tag, value)    => .find(#key->asString = #value)
    public find(key::string, value) => .find(#key = #value)

    public asMap() => .find->asMap
}