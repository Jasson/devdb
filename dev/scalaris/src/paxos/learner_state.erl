% @copyright 2009, 2010 Konrad-Zuse-Zentrum fuer Informationstechnik Berlin,
%                 onScale solutions GmbH

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

%% @author Florian Schintke <schintke@zib.de>
%% @doc Part of generic Paxos-Consensus implementation
%%      The state needed for a single learner instance.
%% @end
-module(learner_state).
-author('schintke@onscale.de').
-vsn('$Id: learner_state.erl 906 2010-07-23 14:09:20Z schuett $').

%% Operations on learner_state
-export([new/4]).
-export([get_paxosid/1]).
-export([get_majority/1]).
-export([set_majority/2]).
-export([get_process_to_inform/1]).
-export([set_process_to_inform/2]).
-export([get_client_cookie/1]).
-export([set_client_cookie/2]).
-export([get_value/1]).
-export([get_round/1]).
-export([get_accepted_count/1]).
-export([add_accepted_msg/3]).

%% learner_state: {PaxosID,
%%                 Majority,
%%                 ProcessToInform
%%                 ClientCookie
%%                 AcceptedCount
%%                 Round
%%                 Value}
%% Value stored to accept messages for a paxos id before learner is
%% initialized. (and for sanity checks)

new(PaxosID, Majority, ProcessToInform, ClientCookie) ->
    {PaxosID, Majority, ProcessToInform, ClientCookie,
     0, 0, paxos_no_value_yet}.

get_paxosid(State) -> element(1, State).
get_majority(State) -> element(2, State).
set_majority(State, Majority) -> setelement(2, State, Majority).
get_process_to_inform(State) -> element(3, State).
set_process_to_inform(State, Pid) -> setelement(3, State, Pid).
get_client_cookie(State) -> element(4, State).
set_client_cookie(State, Pid) -> setelement(4, State, Pid).
get_accepted_count(State) -> element(5, State).
set_accepted_count(State, Num) -> setelement(5, State, Num).
inc_accepted_count(State) -> setelement(5, State, element(5, State) + 1).
get_round(State) -> element(6, State).
set_round(State, Round) -> setelement(6, State, Round).
get_value(State) -> element(7, State).
set_value(State, Value) -> setelement(7, State, Value).

reset_round_and_accepted(State,Round) ->
    TmpState = set_accepted_count(State, 0),
    set_round(TmpState, Round).


add_accepted_msg(State, Round, Value) ->
    case Round < get_round(State) of
        true -> dropped; % outdated round, silently drop it
        false ->
            TmpState = case Round > get_round(State) of
                           true -> reset_round_and_accepted(State, Round);
                           false -> State
                       end,
            Tmp2State = set_value(TmpState, Value),
            NewState = inc_accepted_count(Tmp2State),
            case get_accepted_count(NewState)
                =:= get_majority(NewState) of
                true -> {majority_accepted, NewState};
                false -> {ok, NewState}
            end
    end.
