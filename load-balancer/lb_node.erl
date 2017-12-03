-module(lb_node).

-export([start_link/2]).

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
      spawn_link(fun() -> empty_listeners(ArgsForChild) end);
    _Default -> error
  end.

empty_listeners(ArgsForChild) ->
  [spawn(fun() ->
    lb_worker:start_link(ArgsForChild)
  end) || _ <- lists:seq(1, 50)],
  ok.
