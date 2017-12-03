-module(client_main).

-export([start/0, gen/1, action/2, expect/1]).

-define(PORT, 5551).

%%-define(ADDR, {46, 101, 77, 93}).
-define(ADDR, {127,0,0,1}).

-define(OPTIONS, [binary, {active, false}]).

%% Debug function.
-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).

start() ->
  gen([client]),
  run().

run() ->
  io:fwrite("Press 'm' for messenger or 'b' for bulk bomber."),
  {ok, [Input]} = io:fread("\n [m | b] ", "~s"),
  case Input of
    "m" -> messenger();
    "b" -> bulk();
    _Default -> io:fwrite(Input ++ " is not an option.")
  end,
  run().

bulk() ->
  io:fwrite("\nNumber of clients to spawn: \n"),
  {ok, [Input]} = io:fread("", "~d"),
  for(Input).

for(0) -> ok;

for(N) ->
  spawn(fun() ->

    if
      (N rem 14 =:= 0) -> io:fwrite("\n=");
      true -> io:fwrite("=")
    end,
    {ok, Socket} = gen_tcp:connect(?ADDR, ?PORT, ?OPTIONS),
    ok = gen_tcp:send(Socket, "request"),
    gen_tcp:close(Socket)
  end),
  for(N - 1).

messenger() ->
  {ok, [Input]} = io:fread("\n Message: ", "~s"),
  Response = action(client, list_to_binary(Input)),
  ?PRINT(Response).

gen(Testers) ->
  Pid = spawn(fun() ->
    scenarios(spawn_all_testers(Testers))
  end),
  register(testers, Pid),
  ok.

scenarios(Testers) ->
  receive
    {From, Tester, expect} ->
      [Pid | []] = dict:fetch(Tester, Testers),
      Pid ! {self(), response},
      receive Response -> From ! Response end;
    {From, Tester, Message} ->
      [Pid | []] = dict:fetch(Tester, Testers),
      Pid ! {self(), send, Message},
      %% TODO: Wait for message instead of sleeping.
      timer:sleep(300),
      Pid ! {self(), response},
      receive Response -> From ! Response end
  end,
  scenarios(Testers).

action(Tester, Action) ->
  whereis(testers) ! {self(), Tester, Action},
  receive Response -> Response end.

expect(Tester) ->
  action(Tester, expect).

spawn_all_testers(Testers) ->
  spawn_all_testers(Testers, dict:new()).

spawn_all_testers([], Dict) -> Dict;

spawn_all_testers([Tester | Tail], Dict) ->
  Appended = dict:append(Tester, spawn_tester(Tester), Dict),
  spawn_all_testers(Tail, Appended).

spawn_tester(Name) ->
  {ok, Socket} =  gen_tcp:connect(?ADDR, ?PORT, ?OPTIONS),
  Monitor = spawn(fun() -> monitor_loop(Socket, <<"">>) end),
  Listen = spawn(fun() ->
    listen_loop(Name, Socket, Monitor)
  end),
  ok = gen_tcp:controlling_process(Socket, Listen),
  Monitor.

monitor_loop(Socket, Message) ->
  receive
    {From, response} ->
      From ! Message,
      monitor_loop(Socket, <<"">>);
    {message, New} ->
      monitor_loop(Socket, New);
    {_From, send, Bin} ->
      ok = gen_tcp:send(Socket, Bin),
      monitor_loop(Socket, Message)
    end.

listen_loop(Name, Socket, Monitor) ->
  case gen_tcp:recv(Socket, 0) of
    {error, _Reason} ->
      Monitor ! {message, <<"closed">>};
    {ok, Packet} ->
      Trim = binary:part(Packet, 0, byte_size(Packet) - 3),
      Monitor ! {message, Trim},
      listen_loop(Name, Socket, Monitor)
  end.
