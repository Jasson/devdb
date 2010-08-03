-module(ememcached_app).

% Start the ememcached application

-behaviour(application).

-export([start/2, stop/1]).

start(normal, _Args) ->
    ememcached_sup:start_link().

stop(_Args) ->
    ok.