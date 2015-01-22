-module(client).
-include("config.hrl").
-mode(compile).
-export([main/1]).

main(_) ->
  {ok, Socket} = gen_tcp:connect(?HOST, ?PORT, ?OPTIONS),
  command(Socket).

command(Socket) ->
  case io:get_line("Enter command: ") of
    Data ->
      gen_tcp:send(Socket, Data),
      wait_for_file_info(Socket),
      command(Socket)
  end.

send_file(Socket, Filename, Offset) ->
  case file:open("client/" ++ Filename, [read, binary]) of
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
      gen_tcp:send(Socket, <<2:8/integer>>) % 2 - uploading is done
  end.

wait_for_file_info(Socket) ->
  case gen_tcp:recv(Socket, 0, ?TIMEOUT) of
    {ok, <<Offset:32/integer, Filename/binary>>} ->
      send_file(Socket, binary_to_list(Filename), Offset);
    {error, timeout} ->
      ok
  end.
