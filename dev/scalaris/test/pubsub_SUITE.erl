%  Copyright 2008 Konrad-Zuse-Zentrum fuer Informationstechnik Berlin
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
%%% File    : pubsub_SUITE.erl
%%% Author  : Thorsten Schuett <schuett@zib.de>
%%% Description : Unit tests for src/pubsub/*.erl
%%%
%%% Created :  22 Feb 2008 by Thorsten Schuett <schuett@zib.de>
%%%-------------------------------------------------------------------
-module(pubsub_SUITE).

-author('schuett@zib.de').
-vsn('$Id: pubsub_SUITE.erl 906 2010-07-23 14:09:20Z schuett $').

-compile(export_all).

-include("unittest.hrl").

all() ->
    [test_db].

suite() ->
    [
     {timetrap, {seconds, 120}}
    ].

init_per_suite(Config) ->
    file:set_cwd("../bin"),
    Pid = unittest_helper:make_ring(2),
    [{wrapper_pid, Pid} | Config].

end_per_suite(Config) ->
    %error_logger:tty(false),
    {value, {wrapper_pid, Pid}} = lists:keysearch(wrapper_pid, 1, Config),
    unittest_helper:stop_ring(Pid),
    ok.

test_db(_Config) ->
    ?equals(pubsub_api:get_subscribers("TestTopic"), []),
    ?equals(pubsub_api:subscribe("TestTopic", "http://localhost:8000/pubsub.yaws"), ok),
    ?equals(pubsub_api:get_subscribers("TestTopic"), ["http://localhost:8000/pubsub.yaws"]),
    ?equals(pubsub_api:publish("TestTopic", "TestContent"), ok),
    ?equals(pubsub_api:subscribe("TestTopic", "http://localhost2:8000/pubsub.yaws"), ok),
    ?equals(pubsub_api:unsubscribe("TestTopic", "http://localhost:8000/pubsub.yaws"), ok),
    ?equals(pubsub_api:get_subscribers("TestTopic"), ["http://localhost2:8000/pubsub.yaws"]),
    ?equals(pubsub_api:unsubscribe("TestTopic", "http://localhost:8000/pubsub.yaws"), {fail, not_found}),
    ?equals(pubsub_api:get_subscribers("TestTopic"), ["http://localhost2:8000/pubsub.yaws"]),
    ?equals(pubsub_api:unsubscribe("TestTopic", "http://localhost2:8000/pubsub.yaws"), ok),
    ?equals(pubsub_api:get_subscribers("TestTopic"), []),
    ok.

