%%%-------------------------------------------------------------------
%%% @author rcmerci <rcmerci@562837353@qq.com>
%%% @copyright (C) 2014, rcmerci
%%% @doc
%%%
%%% @end
%%% Created :  3 Oct 2014 by rcmerci <rcmerci@562837353@qq.com>
%%%-------------------------------------------------------------------
-module(http_layer).

-behaviour(gen_server).

%% API
-export([start_link/1,
         start_link/0,
         start_http/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% test export
-export([get_uri/1,get_uri/3,test/1, fetch/1]).


%% spawn export
-export([worker/1, accept_then_spawn/1]).
-record(state, {}).
-define(PORT, 8414).
-define(SERVER, default).
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
start_link(ServerName) when is_list(ServerName)->
    lists:map(fun(E)->gen_server:start_link({local, E}, ?MODULE, [], []) end, [?SERVER|ServerName]);
start_link(ServerName) ->
    gen_server:start_link({local, ServerName}, ?MODULE, [], []).
start_link()->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

test(Server) ->
    gen_server:call(Server, {test}).

-spec static_file(Uri)-> Reply when
      Uri::string(), Reply::any().
static_file(Uri) ->
    gen_server:call(?SERVER, {uri, Uri}).



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
handle_call({uri, URI}, _From, State) ->
    {reply, fetch(URI), State};
handle_call({websocket, _URI}=Request, _From, State) ->
    {reply, Request, State};
handle_call(Request, From, State) ->
    timer:sleep(1000),
    Reply = {Request, From},
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
-record(e404, {head = <<"HTTP/1.1 404 Not Found\r\nServer: holy fucking shit\r\n\r\n">>}).
-record(normal, {head = <<"HTTP/1.1 200 OK\r\nServer: holy fucking shit\r\n\r\n">>}).


start_http() ->
    {ok, Ls} = open_port(),
    start_link(),
    spawn_link(?MODULE, accept_then_spawn, [Ls]).

open_port() ->
    open_port(?PORT).
open_port(Port) ->
    gen_tcp:listen(Port, [binary, {packet, 0}, {active, false}]).

accept_then_spawn(S) ->
    {ok, Acs} = gen_tcp:accept(S),
    spawn(?MODULE, worker, [Acs]),
    accept_then_spawn(S).

worker(S) ->
    io:format("worker:~p~n", [self()]),
    {ok, Packet} = do_recv(S),
    {ok, Uri} = get_uri(Packet),
    RetContent = case static_file(Uri) of
                     {ok, File}->
                         T = #normal{},
                         [T#normal.head, File];
                     {error, _} ->
                         T = #e404{},
                         [T#e404.head];
                     Else ->
                         io:format("error at ~p:~p~n", [?LINE, Else])
                 end,
    sendback(S, RetContent).


do_recv(S) ->
    case gen_tcp:recv(S, 0) of
        {ok, Packet} ->
            {ok, Packet};
        {error, closed} ->
            {error, closed};
        {error, Reason} ->
            {error, Reason}
    end.

%% get uri for binary ,such as <<"GET /s/d HTTP/1.1">> -> "/s/d"
-spec get_uri(Packet)->{ok, Uri}|{error, nouri} when
      Packet::binary(), Uri::string().
get_uri(Packet) ->
    get_uri(binary_to_list(Packet), [], notstart).

get_uri([$G, $E, $T, $\s|S], SoFar, notstart) ->
    get_uri(S, SoFar, started);
get_uri([_H|S], SoFar, notstart) ->
    get_uri(S, SoFar, notstart);
get_uri(_S, [$1, $., $1, $/, $P, $T, $T, $H, $\s|SoFar], started) ->
    {ok, lists:reverse(SoFar)};
get_uri([H|S], SoFar, started) ->
    get_uri(S, [H|SoFar], started);
get_uri([], _SoFar, _) ->
    {error, nouri}.

-spec sendback(_S, Content)->term() when
      Content::list().
sendback(S, Content) ->
    lists:foreach(fun(A)->gen_tcp:send(S, A) end, Content),
    inet:close(S).

%% get static file return as binary
-spec fetch(Uri)->{ok, File}|{error, _Reason} when
      Uri::string(), File::binary().
fetch(Uri) ->
    [$/|TakeOffPreFix] = Uri,
    file:read_file(TakeOffPreFix).



%% http response shortcut
httpresponse(S, e404) ->
    T = #e404{},
    sendback(S, [T#e404.head]).
