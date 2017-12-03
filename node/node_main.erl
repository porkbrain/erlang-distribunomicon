-module(node_main).

-export([start/0, resolver/0]).

%% Debug function.
-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).

start() ->
	?PRINT(node()),
	timer:sleep(infinity).

resolver() ->
	receive
		{From, message, Message} ->
			?PRINT(Message),
			From ! {response, <<"This aint gonna work bby">>},
			resolver()
	end.
