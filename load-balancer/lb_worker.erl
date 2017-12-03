-module(lb_worker).

-behaviour(gen_server).

-record(worker, {
  node,
  socket
}).

-export([start_link/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).

-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).

start_link(Socket, Node) ->
  Worker = #worker{node=Node, socket=Socket},
  {ok, _Pid} = gen_server:start_link(?MODULE, Worker, []).

init(Worker) ->
  process_flag(trap_exit, true),
  gen_server:cast(self(), accept),
  {ok, Worker}.

handle_cast(accept, Worker = #worker{socket=ListenSocket, node=_Node}) ->
  ?PRINT("OK"),
  {ok, AcceptSocket} = gen_tcp:accept(ListenSocket),
  gen_tcp:send(AcceptSocket, "crap"),
  ?PRINT(AcceptSocket),
  lb_node:start_socket(),
  {noreply, Worker}.

handle_info({tcp, Socket, Message}, Worker) ->
  ?PRINT(Message),
  gen_tcp:close(Socket),
  {stop, normal, Worker};

handle_info({tcp_closed, _Socket}, Worker) -> {stop, normal, Worker};
handle_info({tcp_error, _Socket, _}, Worker) -> {stop, normal, Worker};
handle_info(Ex, Worker) ->
  ?PRINT(Ex),
  {noreply, Worker}.

code_change(_OldVsn, State, _Extra) -> {ok, State}.

terminate(normal, _Worker) -> ?PRINT("terminated");
terminate(Reason, _Worker) -> ?PRINT(Reason).

handle_call(_E, _From, Worker) -> {noreply, Worker}.
