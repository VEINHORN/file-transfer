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
      io:format("~s", [Packet]),
      handle(Socket);
    {ok, <<"UPLOAD ", Packet/binary>>} ->
      Filename = delete_n(binary_to_list(Packet)),
      Offset = filelib:file_size("server/" ++ Filename),
      gen_tcp:send(Socket, [<<Offset:32/integer>>, Filename]),
      {ok, IoDevice} = file:open("server/" ++ Filename, [append]),
      wait_for_file(Socket, IoDevice, Offset),
      handle(Socket);
    {error, closed} ->
      handle(Socket);
    _ ->
      ok
  end.

wait_for_file(Socket, IoDevice, Offset) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, <<1:8/integer, Packet/binary>>} ->
      io:format("wait for file~n"),
      file:write(IoDevice, Packet),
      wait_for_file(Socket, IoDevice, Offset);
    {ok, <<0:8/integer>>} ->
      io:format("file not found.~n");
    {ok, <<2:8/integer>>} ->
      io:format("file received.~n")
  end.

delete_n(Str) ->
  string:substr(Str, 1, string:len(Str) - 1).
