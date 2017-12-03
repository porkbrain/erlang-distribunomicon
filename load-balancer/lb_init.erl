-module(lb_init).

-export([start/0]).

-import(lb_node, [acceptor/0]).

-define(OPTIONS, [
	binary,
  {ip, {127, 0, 0, 1}},
	{packet, 0},
	{backlog, 1000},
	{active, false},
	{keepalive, true},
	{reuseaddr, true}
]).

%% Debug function.
-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).

start() ->
	Pid = spawn_link(fun() ->
		{ok, ListenSocket} = gen_tcp:listen(5551, ?OPTIONS),
		Pid = spawn(fun() -> balancer(ListenSocket) end),
    register(balancer, Pid),
		%keepalive(ListenSocket)
		timer:sleep(infinity)
	end),
	register(server, Pid),
  admin().

%keepalive(ListenSocket) -> keepalive(ListenSocket).

balancer(ListenSocket) ->
  receive
    {add_node, Node} ->
      spawn(fun() -> lb_node:start_link(ListenSocket, Node) end),
			balancer(ListenSocket)
  end.

report([]) -> ok;

report([Node | Tail]) ->
	io:fwrite("\nRequests handled by "),
	Resolver = spawn(Node, node_main, resolver, []),
	io:fwrite(Node),
	io:fwrite(": "),
	Resolver ! {self(), report},
	receive
		{response, Response} ->
			io:fwrite(Response)
	end,
	report(Tail).

admin() ->
  {ok, [Input]} = io:fread("\n> ", "~s"),
  Node = list_to_atom(Input),
	case Node of
		exit -> exit(whereis(server), ok);
		report ->
			report(nodes()),
			admin();
		_Default ->
		  balancer ! {add_node, Node},
			admin()
	end.
