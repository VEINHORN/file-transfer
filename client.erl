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
      case wait_for_command(Socket) of
        exit ->
          ok;
        _ ->
          command(Socket)
      end
  end.

switch_command(Socket, Filename, Offset, Command) ->
  case Command of
    ?UPLOAD ->
      utils:send_file(Socket, Filename, Offset, ?CLIENT_FOLDER);
    ?DOWNLOAD ->
      ClientOffset = filelib:file_size(?CLIENT_FOLDER ++ Filename),
      gen_tcp:send(Socket, <<?APPROVEMENT:8/integer, ClientOffset:32/integer>>),
      {ok, IoDevice} = file:open(?CLIENT_FOLDER ++ Filename, [append]),
      utils:wait_for_file(Socket, IoDevice)
  end.

wait_for_command(Socket) ->
  case gen_tcp:recv(Socket, 0, ?TIMEOUT) of
    {ok, <<Offset:32/integer, Command:8/integer, Filename/binary>>} ->
      switch_command(Socket, binary_to_list(Filename), Offset, Command);
    {error, closed} ->
      io:format("You exited."),
      exit;
    {error, timeout} ->
      ok
  end.
