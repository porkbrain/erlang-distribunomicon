-module(lb_node).

-export([init/2]).
-export([start_link/2, start_socket/1]).

-import(lb_worker, [start_link/1]).

-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).

init(ListenSocket, Node) ->
  case net_kernel:connect_node(Node) of
    true ->
      io:fwrite("Starting resolver."),
      {ok, [ListenSocket, Node]};
    false ->
      ?PRINT("Couldn't connect to the node."),
      false
  end.

start_link(ListenSocket, Node) ->
  io:fwrite("Starting node."),
  case init(ListenSocket, Node) of
    {ok, ArgsForChild} ->
      register(Node, spawn_link(fun() -> supervisor([], ArgsForChild) end)),
      spawn_link(fun() -> empty_listeners(Node) end);
    _Default -> error
  end.

supervisor(Children, ArgsForChild) ->
  receive
    {new, child} ->
      Pid = spawn(fun() -> lb_worker:start_link(ArgsForChild) end),
      supervisor([Pid | Children], ArgsForChild)
  end.

start_socket(Node) ->
  %io:fwrite("Starting worker."),
  Node ! {new, child}.

empty_listeners(Node) ->
  [start_socket(Node) || _ <- lists:seq(1, 15)],
  ok.
