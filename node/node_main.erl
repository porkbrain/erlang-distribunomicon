-module(node_main).

-export([start/0, resolver/0]).

%% Debug function.
-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).

start() ->
	?PRINT(node()),
	register(local, spawn(fun() -> server(0) end)),
	timer:sleep(infinity).

server(N) ->
	receive
		inc ->
			server(N + 1);
		{From, read} ->
			From ! N,
			server(N)
	end.

resolver() ->
	receive
		{From, message, Message} ->
			Node = atom_to_binary(node(), utf8),
			Length = integer_to_binary(byte_size(Message)),
			From ! {response, list_to_binary([Node, <<"; Length">>, Length])},
			local ! inc;
		{From, report} ->
			local ! {self(), read},
			receive
				N -> From ! {response, integer_to_binary(N)}
			end
		after 500 ->
			exit(timeout)
	end.
