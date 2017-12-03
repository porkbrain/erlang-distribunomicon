-module(lb_node).

-behaviour(supervisor).

-export([init/1]).
-export([start_link/1, start_socket/0]).

-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).

init([ListenSocket, Node]) ->
  case net_kernel:connect_node(Node) of
    true ->
      %Pid = spawn(Node, node_main, resolver, []),
      %spawn(fun() -> acceptor(ListenSocket, {Node, Pid}, 0, "#1") end);
      spawn_link(fun empty_listeners/0),
      {ok, {{simple_one_for_one, 60, 3600},
        [{listener,
          {lb_worker, start_link, [ListenSocket, Node]},
          temporary, 100, worker, [lb_worker]}
        ]}};
    false ->
      ?PRINT("Couldn't connect to the node.")
  end.

start_link(Args) ->
  {ok, _Pid} = supervisor:start_link({local, ?MODULE}, ?MODULE, Args).

start_socket() ->
  {ok, _Pid} = supervisor:start_child(?MODULE, []).

empty_listeners() ->
  start_socket(),
  ok.

%%acceptor({error, Reason}, Node, _, _Thread) ->
%%  ?PRINT(Node),
%%  ?PRINT(Reason);
%%
%%acceptor(ListenSocket, Node = {Name, _Pid}, Counter, Thread) ->
%%  io:fwrite(atom_to_list(Name) ++ Thread ++ ": " ++ integer_to_list(Counter)),
%%  {ok, AcceptSocket} = gen_tcp:accept(ListenSocket),
%%  spawn(fun() -> acceptor(ListenSocket, Node, Counter + 1, Thread) end),
%%	loop(AcceptSocket, Node).

%%loop(Socket, Node) ->
%%	inet:setopts(Socket, [{active, once}]),
%%	receive
%%		{tcp, _From, Message} ->
%%      {_, Pid} = Node,
%%      Pid ! {self(), message, Message},
%%      receive
%%        {response, Response} ->
%%          gen_tcp:send(Socket, Response)
%%      end,
%%      loop(Socket, Node)
%%	end.
