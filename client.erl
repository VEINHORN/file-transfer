-module(client).
-include("config.hrl").
-mode(compile).
-export([main/1]).

main(_) ->
  {ok, Socket} = gen_tcp:connect(?HOST, ?PORT, [binary, {packet, 4}, {active, false}]),
  command(Socket).

command(Socket) ->
  case io:get_line("Enter command: ") of
    Data ->
      gen_tcp:send(Socket, Data),
      [Offset, Filename] = wait_for_file_info(Socket),
      io:format("~B ~p", [Offset, Filename]),
      send_file(Socket, Filename, Offset),
      io:format("File was succsesfully sended."),
      command(Socket)
  end.

send_file(Socket, Filename, Offset) ->
  case file:open("client/" ++ Filename, [read, binary]) of
    {ok, IoDevice} ->
      send_file_binary(Socket, IoDevice, Offset);
    {error, enoent} ->
      io:format("File does not exist~n"),
      gen_tcp:send(Socket, <<0:32/integer>>)
  end.

send_file_binary(Socket, IoDevice, Offset) ->
  case file:pread(IoDevice, Offset, 1000) of
    {ok, Data} ->
      io:format("~B bytes sent.", [Offset + 1000]),
      gen_tcp:send(Socket, <<1:32/integer, Data/binary>>),
      send_file_binary(Socket, IoDevice, Offset + 1000);
    eof ->
      io:format("File sent."),
      gen_tcp:send(Socket, <<2:32/integer>>) % 2 - uploading is done
  end.

wait_for_file_info(Socket) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, <<Offset:32/integer, Filename/binary>>} ->
      [Offset, binary_to_list(Filename)]
  end.
