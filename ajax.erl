%%%-------------------------------------------------------------------
%%% @author rcmerci <rcmerci@562837353@qq.com>
%%% @copyright (C) 2014, rcmerci
%%% @doc
%%%
%%% @end
%%% Created :  7 Oct 2014 by rcmerci <rcmerci@562837353@qq.com>
%%%-------------------------------------------------------------------
-module(ajax).

-behaviour(gen_server).

%% API
-export([start_link/0, post_ajax_call/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).
%% ets:rectTable:{id,mineNumberFound,details}
%% @details:具体的分布
%% @id:just id for config
-record(state, {rectTable}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% Packet::binary()
post_ajax_call(S, Packet) ->
    gen_server:call(?SERVER, {ajax, {S, Packet}}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    Tid = ets:new(rectTable, [public, {keypos, 1}]),
    {ok, #state{rectTable = Tid}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call({ajax, {S, Packet}}, _From, State) ->
    HeadAndBody = binary:split(Packet, [<<"\r\n\r\n">>]),
    [_Heads, PostContent] = HeadAndBody,
    PostList = binary:split(PostContent, [<<"&">>], [global]),
    PostList2 = [list_to_tuple(binary:split(T, [<<"=">>])) || T<-PostList],
    {_, Id} = lists:keyfind(<<"id">>, 1, PostList2),
    Reply = lists:map(handle_ajax(S, State, Id), PostList2),
    io:format("reply:~p~n", [Reply]),
    {reply, Reply, State};
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

handle_ajax(S, State, Id) ->
    fun(Tuple) ->
            handle_ajax(S, State, Id, Tuple)
    end.

handle_ajax(_S, State, Id, {<<"mineHasFound">>, BinValue}) ->
    io:format("minehasfound:~p~n", [BinValue]),
    case ets:update_element(State#state.rectTable, Id, {2, BinValue}) of
        true ->
            <<"ok">>;
        false ->
            ets:insert(State#state.rectTable, {Id, BinValue, undefined})
    end,

handle_ajax(_S, State, Id, {Bk, Bv}) ->
    io:format("default:~p~p~n", [Bk, Bv]),
    <<"nosense">>.


get_other_info(Id, State) ->
    case ets:first(State#state.rectTable) of
        First when First == Id ->
            get_other_info(First, [], [], State);
        _Other ->
            [Rf] = ets:lookup(State#state.rectTable, Id),
            get_other_info(First, [Id], [Rf], State)
    end.

get_other_info(Prev, Except, SoFar, State)->
    pass;
get_other_info(Prev, [], SoFar, State) ->
    case ets:next(State#state.rectTable, Prev) of
        '$end_of_table' ->
            SoFar;
        K ->
            [R] = ets:lookup(State#state.rectTable, K),
            get_other_info(K, [], [R|SoFar], State)
    end;
get_other_info() ->
