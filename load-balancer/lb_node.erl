-module(lb_node).

-export([boot/2]).

%% Debug function.
-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).

boot(ListenSocket, Node) ->
  case net_kernel:connect_node(Node) of
    true ->
      Pid = spawn(Node, node_main, resolver, []),
      spawn(fun() -> acceptor(ListenSocket, {Node, Pid}, 0, "#1") end),
      spawn(fun() -> acceptor(ListenSocket, {Node, Pid}, 0, "#2") end);
    false ->
      ?PRINT("Couldn't connect to the node.")
  end.


acceptor({error, Reason}, Node, _, _Thread) ->
  ?PRINT(Node),
  ?PRINT(Reason);

acceptor({ok, ListenSocket}, Node = {Name, _Pid}, Counter, Thread) ->
  io:fwrite(atom_to_list(Name) ++ Thread ++ ": " ++ integer_to_list(Counter)),
  {ok, AcceptSocket} = gen_tcp:accept(ListenSocket),
  spawn(fun() -> acceptor({ok, ListenSocket}, Node, Counter + 1, Thread) end),
	loop(AcceptSocket, Node).

loop(Socket, Node) ->
	inet:setopts(Socket, [{active, once}]),
	receive
		{tcp, _From, Message} ->
      {_, Pid} = Node,
      Pid ! {self(), message, Message},
      receive
        {response, Response} ->
          gen_tcp:send(Socket, Response)
      end,
      loop(Socket, Node)
	end.
