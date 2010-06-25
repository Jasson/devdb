%%%-------------------------------------------------------------------
%%% File    : e2d_mgr_nodes.erl
%%% Author  : liqiang 
%%% Description : 
%%%
%%% Created : 21 Jun 2010 by liqiang 
%%%-------------------------------------------------------------------
-module(e2d_mgr_nodes).
-include("e2d_manager.hrl").
-behaviour(gen_server).
-define(SERVER, ?MODULE).

%% 模块说明:
%% 这个模块管理所有的node信息, 对外提供了搜索的功能.
%%
%% 添加 -> 我们可以添加node到这个模块中, 添加时候的key是node的id,
%%        也就是用不同的id来区分不同的node.
%% 获取 -> 我们提供了根据IP的搜索功能, 可以根据IP来搜索Node.
%%
%% gen_server的State就是一个node_info的列表, 如:
%% [{node_info, 1, name1, {192.169.0.1}}, 
%%  {node_info, 2, name2, {192.169.0.2}}, 
%%  {node_info, 3, name3, {192.169.0.3}}]
%%
%% 数据结构:
%% node_info, 一个node是一个三元组, id, name和ip
%% the node info in the manager
%% -record(node_info, {
%%     id = 0 :: non_neg_integer(),
%%     name = '' :: atom(),
%%     ip = {0, 0, 0, 0} :: ip_address()
%% }).

%% API
-export([add_node/1, add_node/3]).
-export([get_node/1, get_nodes/0, exclude_node/2]).
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

add_node(Node = #node_info{}) ->
    gen_server:call(?SERVER, {add_node, Node}).

add_node(Id, Name, Ip)
    when is_integer(Id) andalso is_atom(Name) andalso is_list(Ip)  ->
    {ok, IpTuple} = inet_parse:address(Ip),
    add_node(#node_info{id = Id, name = Name, ip = IpTuple}).

get_node(Ip) when is_list(Ip) ->
    {ok, IpTuple} = inet_parse:address(Ip),
    get_node(IpTuple);
get_node(Ip) when is_tuple(Ip) ->
    gen_server:call(?SERVER, {get_node, Ip}).

%% 返回State, 也就是node_info的列表.
get_nodes() ->
    gen_server:call(?SERVER, {get_all}).

%% 删除Nodes中(第一个)FileName为Value的项目, 返回新的node列表.
%%
%% 例如:
%% 删除Nodes0中id为12的node, 返回一个新的node的列表Nodes.
%% Nodes0 = e2d_mgr_nodes:get_nodes(),
%% Nodes = e2d_mgr_nodes:exclude_node({id, 12}, Nodes0),
exclude_node({FieldName, Value}, Nodes) ->
    Fields = record_info(fields, node_info), %% Note: return [id, name, ip] not [node_info, id, name, ip]

    %% 小技巧, 如何获取list中的keypos :)
    PreList = lists:takewhile(fun(F) when F =:= FieldName -> false;
                                (_F) -> true
                             end,
                            Fields),
    KeyPos = length(PreList) + 2,
    case lists:keytake(Value, KeyPos, Nodes) of
        {value, _, Nodes2} ->
            Nodes2;
        false ->
            Nodes
    end.

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%====================================================================
%% gen_server callbacks
%%====================================================================

%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init([]) ->
    {ok, []}.

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call({add_node, #node_info{id = Id} = Node}, _From, State) ->
    State2  = lists:keystore(Id, #node_info.id, State, Node),
    {reply, ok, State2};
handle_call({get_node, IP}, _From, State) ->
    Reply =
    case lists:keysearch(IP, #node_info.ip, State) of
        {value, Tuple} ->
            Tuple;
        false ->
            false
    end,
    {reply, Reply, State};
handle_call({get_all}, _From, State) ->
    {reply, State, State};
handle_call(_Req, _From, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
