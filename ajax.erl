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

-record(state, {}).

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
    {ok, #state{}}.

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
    Reply = lists:map(handle_ajax(S), PostList2),
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

handle_ajax(S) ->
    fun(Tuple) ->
            handle_ajax(S, Tuple)
    end.

handle_ajax(_S, {<<"mineHasFound">>, BinValue}) ->
    io:format("minehasfound:~p~n", [BinValue]),
    <<"ok">>;
handle_ajax(_S, _Tuple) ->
    io:format("default:nosense"),
    <<"nosense">>.
