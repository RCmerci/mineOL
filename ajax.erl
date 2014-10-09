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
%% for test
-export([quote/2, unquote/2, ets_info/0]).
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

ets_info() ->
    gen_server:call(?SERVER, {ets_info}).

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
handle_call({ets_info}, _From, State) ->
    R = case ets:first(State#state.rectTable) of
            '$end_of_table' ->
                [];
            K ->
                [V] = ets:lookup(State#state.rectTable, K),
                [V | get_ets_info(State, K)]
        end,
    {reply, R, State};
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
    %% io:format("minehasfound:mineHasFound:~p,~p~n", [Id, BinValue]),
    update_rectTable(State, Id, {2, BinValue}),
    OtherInfo = get_other_info(Id, State),
    format_info(OtherInfo);
handle_ajax(_S, State, Id, {<<"rectTable">>, BinValue}) ->
    io:format("rectTable:Id:~p,~p~n", [Id, BinValue]),
    update_rectTable(State, Id, {3, BinValue}),
    OtherInfo = get_other_info(Id, State),
    format_info(OtherInfo);
handle_ajax(_S, State, Id, {<<"willLeave">>, BinValue}) ->
    io:format("willLeave:Id:~p,~p~n", [Id, BinValue]),
    update_rectTable(State, Id, {willLeave, true}),
    <<"ok">>;
handle_ajax(_S, _State, _Id, {<<"id">>, _}) ->
    <<>>;
handle_ajax(_S, _State, _Id, {Bk, Bv}) ->
    io:format("default:~p~p~n", [Bk, Bv]),
    <<"nosense">>.


get_other_info(Id, State) ->
    case ets:first(State#state.rectTable) of
        '$end_of_table' ->
            [];
        First when First == Id ->
            get_other_info(First, [], [], State);
        First ->
            [Rf] = ets:lookup(State#state.rectTable, First),
            get_other_info(First, [Id], [Rf], State)
    end.

get_other_info(Prev, [Except], SoFar, State)->
    case ets:next(State#state.rectTable, Prev) of
        Except ->
            get_other_info(Except, [], SoFar, State);
        '$end_of_table' ->
            SoFar;
        OtherK ->
            [R] = ets:lookup(State#state.rectTable, OtherK),
            get_other_info(OtherK, [Except], [R|SoFar], State)
    end;
get_other_info(Prev, [], SoFar, State) ->
    case ets:next(State#state.rectTable, Prev) of
        '$end_of_table' ->
            SoFar;
        K ->
            [R] = ets:lookup(State#state.rectTable, K),
            get_other_info(K, [], [R|SoFar], State)
    end.


update_rectTable(State, Id, {2, BinValue}) ->
    case ets:update_element(State#state.rectTable, Id, {2, BinValue}) of
        true ->
            true;
        false ->
            ets:insert(State#state.rectTable, {Id, BinValue, <<"undefined">>})
    end,
    ok;
update_rectTable(State, Id, {3, BinValue}) ->
    case ets:update_element(State#state.rectTable, Id, {3, BinValue}) of
        true ->
            true;
        false ->
            ets:insert(State#state.rectTable, {Id, <<"undefined">>, BinValue})
    end,
    ok;
update_rectTable(State, Id, {willLeave, true}) ->
    ets:delete(State#state.rectTable, Id),
    ok.

format_info(Info) ->
    list_to_binary(
      lists:map(fun({Id, MineFound, Detail})->
                        list_to_binary("id:" ++ binary_to_list(Id) ++
                                           "mineHasFound:" ++ binary_to_list(MineFound) ++
                                           "rectTable:" ++ binary_to_list(Detail))
                end, Info)).


-spec quote(C, SoFar)->list() when
      C::list(), SoFar::list().
quote([$;|R], SoFar) ->
    quote(R, [$B, $3, $% | SoFar]);
quote([$\s|R], SoFar) ->
    quote(R, [$0, $2, $% | SoFar]);
quote([$?|R], SoFar) ->
    quote(R, [$F, $3, $% | SoFar]);
quote([$:|R], SoFar) ->
    quote(R, [$A, $3, $% | SoFar]);
quote([$@|R], SoFar) ->
    quote(R, [$0, $4, $% | SoFar]);
quote([$&|R], SoFar) ->
    quote(R, [$6, $2, $% | SoFar]);
quote([$=|R], SoFar) ->
    quote(R, [$D, $3, $% | SoFar]);
quote([$+|R], SoFar) ->
    quote(R, [$B, $2, $% | SoFar]);
quote([$$|R], SoFar) ->
    quote(R, [$4, $2, $% | SoFar]);
quote([$,|R], SoFar) ->
    quote(R, [$C, $2, $% | SoFar]);
quote([$/|R], SoFar) ->
    quote(R, [$F, $2, $% | SoFar]);
quote([H|R], SoFar) ->
    quote(R, [H | SoFar]);
quote([], SoFar) ->
    lists:reverse(SoFar).

unquote([$%, $3, $B | R], SoFar) ->
    unquote(R, [$; | SoFar]);
unquote([$%, $2, $0 | R], SoFar) ->
    unquote(R, [$\s | SoFar]);
unquote([$%, $3, $F | R], SoFar) ->
    unquote(R, [$? | SoFar]);
unquote([$%, $3, $A | R], SoFar) ->
    unquote(R, [$: | SoFar]);
unquote([$%, $4, $0 | R], SoFar) ->
    unquote(R, [$@ | SoFar]);
unquote([$%, $2, $6 | R], SoFar) ->
    unquote(R, [$& | SoFar]);
unquote([$%, $3, $D | R], SoFar) ->
    unquote(R, [$= | SoFar]);
unquote([$%, $2, $B | R], SoFar) ->
    unquote(R, [$+ | SoFar]);
unquote([$%, $2, $4 | R], SoFar) ->
    unquote(R, [$$ | SoFar]);
unquote([$%, $2, $C | R], SoFar) ->
    unquote(R, [$, | SoFar]);
unquote([$%, $2, $F | R], SoFar) ->
    unquote(R, [$/ | SoFar]);
unquote([H|R], SoFar) ->
    unquote(R, [H|SoFar]);
unquote([], SoFar) ->
    SoFar.


get_ets_info(State, Prev) ->
    case ets:next(State#state.rectTable, Prev) of
        '$end_of_table' ->
            [];
        K ->
            [V] = ets:lookup(State#state.rectTable, K),
            [V | get_ets_info(State, K)]
    end.
