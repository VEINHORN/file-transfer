-module(server).
-include("config.hrl").
-mode(compile).
-export([main/1]).

main(_) ->
  listen().

listen() ->
  {ok, LSock} = gen_tcp:listen(?PORT, ?OPTIONS),
  accept(LSock).

accept(LSock) ->
  {ok, Sock} = gen_tcp:accept(LSock),
  handle(Sock),
  accept(LSock).

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
      {ok, IoDevice} = file:open("server/" ++ Filename, [append]),
      wait_for_file(Socket, IoDevice),
      handle(Socket);
    {error, closed} ->
      handle(Socket);
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

wait_for_file(Socket, IoDevice) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, <<?SENDING:8/integer, Packet/binary>>} ->
      file:write(IoDevice, Packet),
      wait_for_file(Socket, IoDevice);
    {ok, <<?FILE_NOT_EXIST:8/integer>>} ->
      io:format("File not found.~n");
    {ok, <<?DOWNLOADED:8/integer>>} ->
      io:format("File received.~n")
  end.
