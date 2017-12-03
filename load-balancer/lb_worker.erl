-module(lb_worker).

-record(worker, {
  node,
  resolver,
  socket
}).

-export([start_link/1]).

-import(lb_node, [start_socket/1]).

-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).

start_link([ListenSocket, Node]) ->
  Worker = #worker{node=Node},
  {ok, spawn(fun() -> acceptor(ListenSocket, Worker) end)}.

  acceptor({error, Reason}, Worker) ->
    ?PRINT(Worker),
    ?PRINT(Reason);

  acceptor(ListenSocket, Worker = #worker{node=Node}) ->
    {ok, AcceptSocket} = gen_tcp:accept(ListenSocket),
    spawn(fun() -> start_link([ListenSocket, Node]) end),
    Resolver = spawn(Node, node_main, resolver, []),
  	loop(Worker#worker{socket=AcceptSocket, resolver=Resolver}).

  loop(Worker = #worker{socket=Socket, resolver=Resolver}) ->
  	inet:setopts(Socket, [{active, once}]),
  	receive
  		{tcp, _From, Message} ->
        Resolver ! {self(), message, Message},
        receive
          {response, Response} ->
            gen_tcp:send(Socket, Response)
        end,
        loop(Worker)
  	end.
