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
      Filename = delete_n(binary_to_list(Packet)),
      Offset = filelib:file_size("server/" ++ Filename),
      gen_tcp:send(Socket, [<<Offset:32/integer, 4:8/integer>>, Filename]),
      wait_for_approvement(Socket, Filename),
      handle(Socket);
    {ok, <<"UPLOAD ", Packet/binary>>} ->
      Filename = delete_n(binary_to_list(Packet)),
      Offset = filelib:file_size("server/" ++ Filename),
      gen_tcp:send(Socket, [<<Offset:32/integer, 3:8/integer>>, Filename]), % if offset 0 file doesn't exist
      {ok, IoDevice} = file:open("server/" ++ Filename, [append]),
      wait_for_file(Socket, IoDevice, Offset),
      handle(Socket);
    {error, closed} ->
      handle(Socket);
    _ ->
      ok
  end.

wait_for_approvement(Socket, Filename) ->
  case gen_tcp:recv(Socket, 0, ?TIMEOUT) of
    {ok, <<6:8/integer, Offset:32/integer>>} ->
      send_file(Socket, Filename, Offset),
      ok;
    {error, timeout} ->
      ok
  end.

send_file(Socket, Filename, Offset) ->
  case file:open("server/" ++ Filename, [read, binary]) of
    {ok, IoDevice} ->
      send_file_binary(Socket, IoDevice, Offset);
    {error, enoent} ->
      io:format("File does not exist~n"),
      gen_tcp:send(Socket, <<0:8/integer>>)
  end.

send_file_binary(Socket, IoDevice, Offset) ->
  case file:pread(IoDevice, Offset, ?CHUNK_SIZE) of
    {ok, Data} ->
      io:format("~B bytes sent.~n", [Offset + ?CHUNK_SIZE]),
      gen_tcp:send(Socket, <<1:8/integer, Data/binary>>),
      send_file_binary(Socket, IoDevice, Offset + ?CHUNK_SIZE);
    eof ->
      io:format("File sent.~n"),
      gen_tcp:send(Socket, <<2:8/integer>>)
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
