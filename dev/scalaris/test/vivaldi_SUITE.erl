%%%-------------------------------------------------------------------
%%% File    : vivaldi_SUITE.erl
%%% Author  : Thorsten Schuett <schuett@zib.de>
%%% Description : Unit tests for src/vivaldi.erl
%%%
%%% Created :  18 Feb 2010 by Thorsten Schuett <schuett@zib.de>
%%%-------------------------------------------------------------------
-module(vivaldi_SUITE).

-author('schuett@zib.de').
-vsn('$Id: vivaldi_SUITE.erl 906 2010-07-23 14:09:20Z schuett $').

-compile(export_all).

-include_lib("unittest.hrl").

all() ->
    [test_init,
     test_on_trigger,
     test_on_vivaldi_shuffle,
     test_on_cy_cache1,
     test_on_cy_cache2,
     test_on_cy_cache3].

suite() ->
    [
     {timetrap, {seconds, 10}}
    ].

init_per_suite(Config) ->
    file:set_cwd("../bin"),
    error_logger:tty(true),
    Owner = self(),
    Pid = spawn(fun () ->
                        crypto:start(),
                        process_dictionary:start_link(),
                        config:start_link(["scalaris.cfg", "scalaris.local.cfg"]),
                        comm_port:start_link(),
                        timer:sleep(1000),
                        comm_port:set_local_address({127,0,0,1},14195),
                        application:start(log4erl),
                        Owner ! {continue},
                        receive
                            {done} ->
                                ok
                        end
                end),
    receive
        {continue} ->
            ok
    end,
    % extend vivaldi shuffle interval
    [{wrapper_pid, Pid} | Config].

end_per_suite(Config) ->
    reset_config(),
    {value, {wrapper_pid, Pid}} = lists:keysearch(wrapper_pid, 1, Config),
    gen_component:kill(process_dictionary),
    error_logger:tty(false),
    exit(Pid, kill),
    Config.

init_per_testcase(_TestCase, Config) ->
    Config.

end_per_testcase(_TestCase, Config) ->
    reset_config(),
    Config.

test_init(Config) ->
    config:write(vivaldi_interval, 100),
    InitialState1 = vivaldi:init('trigger_periodic'),
    
    ?equals_pattern(InitialState1, {[_X, _Y], 1.0, {'trigger_periodic', _TriggerState}}),
    ?expect_message({trigger}),
    ?expect_no_message(),
    Config.

test_on_trigger(Config) ->
    process_dictionary:register_process(atom_to_list(?MODULE), cyclon, self()),
    Coordinate = [1.0, 1.0],
    Confidence = 1.0,
    InitialState = {Coordinate, Confidence, get_ptrigger_nodelay()},
    {NewCoordinate, NewConfidence, NewTriggerState} =
        vivaldi:on({trigger}, InitialState),

    Self = self(),
    ?equals(Coordinate, NewCoordinate),
    ?equals(Confidence, NewConfidence),
    ?equals_pattern(NewTriggerState, {'trigger_periodic', _}),
    ?expect_message({get_subset_rand, 1, Self}),
    ?expect_message({trigger}),
    ?expect_no_message(),
    Config.

test_on_vivaldi_shuffle(Config) ->
    config:write(vivaldi_count_measurements, 1),
    config:write(vivaldi_measurements_delay, 0),
    Coordinate = [1.0, 1.0],
    Confidence = 1.0,
    InitialState = {Coordinate, Confidence, get_ptrigger_nodelay()},
    _NewState = vivaldi:on({vivaldi_shuffle, comm:this(), [0.0, 0.0], 1.0},
                                 InitialState),
    receive
        {ping, SourcePid} -> comm:send(SourcePid, {pong})
    end,

    ?expect_message({update_vivaldi_coordinate, _Latency, {[0.0, 0.0], 1.0}}),
    ?expect_no_message(),
    % TODO: check the node's state
    Config.

test_on_cy_cache1(Config) ->
    Coordinate = [1.0, 1.0],
    Confidence = 1.0,
    InitialState = {Coordinate, Confidence, get_ptrigger_nodelay()},
    % empty node cache
    Cache = [],
    NewState =
        vivaldi:on({cy_cache, Cache}, InitialState),

    ?equals(NewState, InitialState),
    % no messages should be send if no node given
    ?expect_no_message(),
    Config.

test_on_cy_cache2(Config) ->
    process_dictionary:register_process(atom_to_list(?MODULE), dht_node, self()),

    Coordinate = [1.0, 1.0],
    Confidence = 1.0,
    InitialState = {Coordinate, Confidence, get_ptrigger_nodelay()},
    % non-empty node cache
    Cache = [node:new(comm:make_global(self()), 10, 0)],
    NewState =
        vivaldi:on({cy_cache, Cache}, InitialState),

    ?equals(NewState, InitialState),
    % no messages sent to itself
    ?expect_no_message(),
    Config.

test_on_cy_cache3(Config) ->
    erlang:put(instance_id, atom_to_list(?MODULE)),
    % register some other process as the dht_node
    DHT_Node = fake_dht_node(),
%%     ?equals(process_dictionary:get_group_member(dht_node), DHT_Node),

    Coordinate = [1.0, 1.0],
    Confidence = 1.0,
    InitialState = {Coordinate, Confidence, get_ptrigger_nodelay()},
    % non-empty node cache
    Cache = [node:new(comm:make_global(self()), 10, 0)],
    NewState =
        vivaldi:on({cy_cache, Cache}, InitialState),

    ?equals(NewState, InitialState),
    % if pids don't match, a get_state is send to the cached node's dht_node
    This = comm:this(),
    ?expect_message({send_to_group_member, vivaldi,
                     {vivaldi_shuffle, This, Coordinate, Confidence}}),
    % no further messages
    ?expect_no_message(),
    
    exit(DHT_Node, kill),
    Config.

reset_config() ->
    config:write(vivaldi_interval, 10000),
    config:write(vivaldi_dimensions, 2),
    config:write(vivaldi_count_measurements, 10),
    config:write(vivaldi_measurements_delay, 1000),
    config:write(vivaldi_latency_timeout, 60000),
    config:write(vivaldi_trigger, trigger_periodic).

get_ptrigger_nodelay() ->
    get_ptrigger_delay(0).

get_ptrigger_delay(Delay) ->
    trigger:init('trigger_periodic', fun () -> Delay end, 'trigger').

fake_dht_node() ->
    DHT_Node = spawn(?MODULE, fake_dht_node_start, [self()]),
    receive
        {started, DHT_Node} -> DHT_Node
    end.

fake_dht_node_start(Supervisor) ->
    process_dictionary:register_process(atom_to_list(?MODULE), dht_node, self()),
    Supervisor ! {started, self()},
    fake_process().

fake_process() ->
    ?consume_message({ok}, 1000),
    fake_process().
