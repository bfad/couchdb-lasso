if(not var_defined(`_couch_loaded`)) => {
    // This should let us run this anywhere and still properly import the files
    local(path_here) = currentCapture->callsite_file->stripLastComponent
    not #path_here->beginsWith('/')? #path_here = io_file_getcwd + '/' + #path_here
    not #path_here->endsWith('/')  ? #path_here->append('/')


    define file_import(f::file) => {
        sourcefile(#f->readString, #f->path, false, false)->invoke
    }
    define dir_import(d::dir, ext::staticarray=(:'lasso', 'inc')) => {
        with f in #d->eachFile
        where #ext->contains(#f->path->split('.')->last)
        order by #f->name
        do file_import(#f)

        with f in #d->eachDir order by #f->name do dir_import(#f)
    }


    dir_import(dir(#path_here + '../libs/'))
    dir_import(dir(#path_here + '../src/'))

    var(_couch_loaded) = true
}