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

switch_command(Socket, Filename, Offset, Command) ->
  case Command of
    3 ->
      send_file(Socket, Filename, Offset);
    4 ->
      io:format("download"),
      ClientOffset = filelib:file_size("client/" ++ Filename),
      gen_tcp:send(Socket, <<6:8/integer, ClientOffset:32/integer>>),
      {ok, IoDevice} = file:open("client/" ++ Filename, [append]),
      wait_for_file(Socket, IoDevice)
  end.

wait_for_file(Socket, IoDevice) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, <<1:8/integer, Packet/binary>>} ->
      file:write(IoDevice, Packet),
      wait_for_file(Socket, IoDevice);
    {ok, <<2:8/integer>>} ->
      io:format("file downloaded.");
    {ok, <<0:8/integer>>} ->
      io:format("file does not exist.")
  end.

wait_for_file_info(Socket) ->
  case gen_tcp:recv(Socket, 0, ?TIMEOUT) of
    {ok, <<Offset:32/integer, Command:8/integer, Filename/binary>>} ->
      switch_command(Socket, binary_to_list(Filename), Offset, Command);
      %send_file(Socket, binary_to_list(Filename), Offset, Command);
    {error, timeout} ->
      ok
  end.
