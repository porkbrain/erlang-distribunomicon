-module(lb_node).

-export([start_link/2]).

-import(lb_worker, [start_link/1]).

-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).

init(ListenSocket, Node) ->
  case net_kernel:connect_node(Node) of
    true ->
      %% Successfully connected to a node.
      {ok, [ListenSocket, Node]};
    false ->
      %% Connection to a node failed.
      false
  end.

start_link(ListenSocket, Node) ->
  %% Attempting to start a new.
  case init(ListenSocket, Node) of
    {ok, ArgsForChild} ->
      spawn_link(fun() -> start_workers(ArgsForChild) end);
    _Default -> error
  end.

start_workers(ArgsForChild) ->
  [spawn(fun() ->
    lb_worker:start_link(ArgsForChild)
  end) || _ <- lists:seq(1, 50)],
  ok.
