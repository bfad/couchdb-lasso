define object_map_array => type {
    trait { import trait_positionallyKeyed, trait_queriable }

    data
        private _list,
        private _type

    public onCreate(data::trait_finiteForEach, asType::tag=tag('')) => {
        ._list = #data
        ._type = #asType
    }

    // Allow for setting the type
    public setType(type::tag) => { ._type = #type }


    public size => ._list->size

    public keys => (1 to .size)->asStaticArray

    public values => {
        local(result) = staticarray_join(.size, void)

        local(i) = .size
        while(#i--) => {
            #result->get(loop_count) = .get(loop_count)
        }

        return #result
    }

    public get(i::integer) => {
        local(result) = ._list->get(#i)
        local(asType) = ._type

        #asType->isA(::tag)
            ? return \(#asType)->invoke(#result)

        return #result
    }

    public forEach => {
        local(i) = .size
        while(#i--) => {
            givenBlock(.get(loop_count))
        }
    }

}