-module(server).
-include("config.hrl").
-mode(compile).
-export([main/1]).

main(_) ->
  listen().

listen() ->
  {ok, LSock} = gen_tcp:listen(?PORT, ?OPTIONS),
  spawn(fun() -> accept(LSock) end),
  timer:sleep(infinity).

accept(LSock) ->
  {ok, Sock} = gen_tcp:accept(LSock),
  spawn(fun() -> accept(LSock) end),
  handle(Sock).

handle(Socket) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, <<"DOWNLOAD ", Packet/binary>>} ->
      [Filename, Offset] = utils:get_file_info(Packet),
      gen_tcp:send(Socket, [<<Offset:32/integer, ?DOWNLOAD:8/integer>>, Filename]),
      wait_for_approvement(Socket, Filename),
      handle(Socket);
    {ok, <<"UPLOAD ", Packet/binary>>} ->
      [Filename, Offset] = utils:get_file_info(Packet),
      gen_tcp:send(Socket, [<<Offset:32/integer, ?UPLOAD:8/integer>>, Filename]),
      {ok, IoDevice} = file:open(?SERVER_FOLDER ++ Filename, [append]),
      utils:wait_for_file(Socket, IoDevice),
      handle(Socket);
    {ok, <<"EXIT\n">>} ->
      gen_tcp:close(Socket);
    {error, closed} ->
      ok;      
    _ ->
      ok
  end.

wait_for_approvement(Socket, Filename) ->
  case gen_tcp:recv(Socket, 0, ?TIMEOUT) of
    {ok, <<?APPROVEMENT:8/integer, Offset:32/integer>>} ->
      utils:send_file(Socket, Filename, Offset, ?SERVER_FOLDER),
      ok;
    {error, timeout} ->
      ok
  end.
