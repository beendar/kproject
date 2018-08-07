local HANDLER= {}

HANDLER['page'] = function(page)
    return {
        page = page,
        list = { {name='yang', age=9999} }
    }
end

HANDLER['echo'] = function(msg)
    dump(msg, 'Echo~~~~~~~~~~~~~')
    return 'echo',  { rp={text=os.time()} }
end


local function launch()
    return 'game.rank', function(_, cmd, ...)
        return HANDLER[cmd](...)
    end
end

return {
    launch = launch
}
