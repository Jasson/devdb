%%
%% Autogenerated by Thrift
%%
%% DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
%%

-module(dynomite_types).

-include("dynomite_types.hrl").

-export([struct_info/1]).
%% struct getResult

% -record(getResult, {context, results}).

struct_info('getResult') ->
  {struct, [{1, string},
  {2, {list, string}}]}
;

%% struct failureException

% -record(failureException, {message}).

struct_info('failureException') ->
  {struct, [{1, string}]}
;

struct_info('i am a dummy struct') -> undefined.