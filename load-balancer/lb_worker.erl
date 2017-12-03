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
  %io:fwrite("Worker booted."),
  {ok, spawn(fun() -> acceptor(ListenSocket, Worker) end)}.

  acceptor({error, Reason}, Worker) ->
    ?PRINT(Worker),
    ?PRINT(Reason);

  acceptor(ListenSocket, Worker = #worker{node=Node}) ->
    %io:fwrite("About to accept a socket."),
    {ok, AcceptSocket} = gen_tcp:accept(ListenSocket),
    %io:fwrite("Let's start a new listen socket."),
    lb_node:start_socket(Node),
    Resolver = spawn(Node, node_main, resolver, []),
    %io:fwrite("Looooooooop."),
  	loop(Worker#worker{socket=AcceptSocket, resolver=Resolver}).

  loop(Worker = #worker{socket=Socket, node=Node, resolver=Resolver}) ->
  	inet:setopts(Socket, [{active, once}]),
  	receive
      {tcp, _From, <<"report", _/binary>>} ->
        io:fwrite("Requests handled by " ++ atom_to_list(Node) ++ ":"),
        Resolver ! {self(), report},
        receive
          {response, Response} ->
            io:fwrite(Response),
            gen_tcp:send(Socket, Response)
        end,
        loop(Worker);
  		{tcp, _From, Message} ->
        %io:fwrite("I've got a message :3"),
        %io:fwrite(Node),
        Resolver ! {self(), message, Message},
        receive
          {response, Response} ->
            %io:fwrite("Response from node"),
            %io:fwrite(Response),
            gen_tcp:send(Socket, Response)
        end,
        loop(Worker)
  	end.
