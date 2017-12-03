-module(lb_init).

-export([start/0]).

-import(lb_node, [acceptor/0]).

-define(OPTIONS, [
	binary,
  {ip, {127, 0, 0, 1}},
	{packet, 0},
	{backlog, 15},
	{active, false},
	{reuseaddr, true}
]).

%% Debug function.
-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).

start() ->
	Pid = spawn_link(fun() ->
		ListenSocket = gen_tcp:listen(5551, ?OPTIONS),
		Pid = spawn(fun() -> balancer(ListenSocket) end),
    register(balancer, Pid),
		timer:sleep(infinity)
	end),
	register(server, Pid),
  admin().

balancer(ListenSocket) ->
  receive
    {add_node, Node} ->
      spawn(fun() -> lb_node:boot(ListenSocket, Node) end),
			balancer(ListenSocket)
  end.

admin() ->
  {ok, [Input]} = io:fread("\n> ", "~s"),
  Node = list_to_atom(Input),
	case Node of
		exit -> exit(whereis(server), ok);
		_Default ->
		  balancer ! {add_node, Node},
			admin()
	end.
