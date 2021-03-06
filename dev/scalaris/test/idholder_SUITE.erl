%  Copyright 2008-2010 Konrad-Zuse-Zentrum fuer Informationstechnik Berlin
%
%   Licensed under the Apache License, Version 2.0 (the "License");
%   you may not use this file except in compliance with the License.
%   You may obtain a copy of the License at
%
%       http://www.apache.org/licenses/LICENSE-2.0
%
%   Unless required by applicable law or agreed to in writing, software
%   distributed under the License is distributed on an "AS IS" BASIS,
%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%   See the License for the specific language governing permissions and
%   limitations under the License.
%%%-------------------------------------------------------------------
%%% File    : idholder_SUITE.erl
%%% Author  : Thorsten Schuett <schuett@zib.de>
%%% Description : Unit tests for src/idholder.erl
%%%
%%% Created :  12 Jun 2008 by Thorsten Schuett <schuett@zib.de>
%%%-------------------------------------------------------------------
-module(idholder_SUITE).

-author('schuett@zib.de').
-vsn('$Id: idholder_SUITE.erl 926 2010-07-27 15:28:54Z schuett $').

-compile(export_all).

-include("unittest.hrl").

all() ->
    [getset_key].

suite() ->
    [
     {timetrap, {seconds, 20}}
    ].

init_per_suite(Config) ->
    file:set_cwd("../bin"),
    Self = self(),
    Pid = spawn(fun () ->
                        config:start_link(["scalaris.cfg", "scalaris.local.cfg"]),
                        crypto:start(),
                        process_dictionary:start_link(),
                        idholder:start_link("foo", []),
                        Self ! continue,
                        timer:sleep(5000)
                end),
    timer:sleep(1000),
    receive
        continue ->
            ok
    end,
    [{wrapper_pid, Pid} | Config].

end_per_suite(Config) ->
    {value, {wrapper_pid, Pid}} = lists:keysearch(wrapper_pid, 1, Config),
    gen_component:kill(process_dictionary),
    exit(Pid, kill),
    ok.

getset_key(_Config) ->
    process_dictionary:register_process("foo", foo, self()),
    idholder:get_id(),
    _X = receive
             {idholder_get_id_response, D, _Dversion} -> D
         end,
    %ct:pal("X: ~p~n",[_X]),
    idholder:set_id("getset_key", 1),
    idholder:get_id(),
    Res = receive
              {idholder_get_id_response, Id, IdVersion} -> {Id, IdVersion}
    end,
    ?equals(Res, {"getset_key", 1}),
    ok.

