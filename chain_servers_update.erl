-module(chain_servers_update).
-export([start/0, serv1/2, serv2/1, serv3/1]).

%% Start the chain by spawning the servers and initiating the message loop
start() ->
    Serv3Pid = spawn(?MODULE, serv3, [0]),  % Start serv3 with accumulator 0
    Serv2Pid = spawn(?MODULE, serv2, [Serv3Pid]),  % Start serv2 and pass serv3 PID
    Serv1Pid = spawn(?MODULE, serv1, [Serv2Pid, self()]),  % Start serv1 and pass serv2 PID and caller PID
    io:format("PIDs: Serv1 = ~p, Serv2 = ~p, Serv3 = ~p~n", [Serv1Pid, Serv2Pid, Serv3Pid]),
    message_loop(Serv1Pid),  % Start the message loop
    {Serv1Pid, Serv2Pid, Serv3Pid}.  % Return the PIDs for optional use

%% Interactive message loop
message_loop(Serv1Pid) ->
    io:format("Enter a message (or 'all_done' to quit): "),
    Input = io:get_line(""),
    case string:trim(Input) of
        "all_done" -> 
            io:format("Stopping...~n"),
            ok;
        "update" -> 
            Serv1Pid ! {update, self()},
            receive
                {new_pid, NewPid} ->
                    io:format("Switched to new Serv1 PID: ~p~n", [NewPid]),
                    message_loop(NewPid)
            after 5000 ->  % Timeout if no new PID is received
                io:format("Update failed to produce a new PID.~n"),
                message_loop(Serv1Pid)
            end;
        Message ->
            case catch erl_scan:string(Message) of
                {ok, Tokens, _} ->
                    case catch erl_parse:parse_term(Tokens) of
                        {ok, Term} ->
                            Serv1Pid ! Term,
                            message_loop(Serv1Pid);
                        _Error ->
                            io:format("Invalid Erlang term, try again.~n"),
                            message_loop(Serv1Pid)
                    end;
                _Error ->
                    io:format("Invalid input format, try again.~n"),
                    message_loop(Serv1Pid)
            end
    end.

%% serv1: handles arithmetic operations and passes unhandled messages to serv2
serv1(Serv2Pid, LoopPid) ->
    receive
        {update, CallerPid} ->
            io:format("(serv1) Updating to newest version. Old PID = ~p~n", [self()]),
            NewPid = spawn(?MODULE, serv1, [Serv2Pid, CallerPid]),
            io:format("(serv1) New instance created with PID = ~p~n", [NewPid]),
            CallerPid ! {new_pid, NewPid},  % Notify the caller about the new PID
            exit(normal);  % Cleanly terminate old process
        {add, X, Y} ->
            Result = X + Y,
            io:format("(serv1) Add ~p + ~p = ~p~n", [X, Y, Result]),
            serv1(Serv2Pid, LoopPid);
        {sub, X, Y} ->
            Result = X - Y,
            io:format("(serv1) Subtract ~p - ~p = ~p~n", [X, Y, Result]),
            serv1(Serv2Pid, LoopPid);
        halt ->
            Serv2Pid ! halt,
            io:format("(serv1) Halting...~n");
        Other ->
            Serv2Pid ! Other,
            serv1(Serv2Pid, LoopPid)
    end.

%% serv2: handles lists of numbers and passes unhandled messages to serv3
serv2(Serv3Pid) ->
    receive
        update ->
            io:format("(serv2) Updating to newest version. Old PID = ~p~n", [self()]),
            NewPid = spawn(?MODULE, serv2, [Serv3Pid]),
            io:format("(serv2) New instance created with PID = ~p~n", [NewPid]),
            exit(normal);  % Cleanly terminate old process
        [H | T] when is_integer(H) ->
            Sum = lists:sum([X || X <- [H | T], is_number(X)]),
            io:format("(serv2) Sum of list: ~p~n", [Sum]),
            serv2(Serv3Pid);
        halt ->
            Serv3Pid ! halt,
            io:format("(serv2) Halting...~n");
        Other ->
            Serv3Pid ! Other,
            serv2(Serv3Pid)
    end.

%% serv3: handles errors and keeps track of unhandled messages
serv3(UnhandledCount) ->
    receive
        update ->
            io:format("(serv3) Updating to newest version. Old PID = ~p~n", [self()]),
            NewPid = spawn(?MODULE, serv3, [UnhandledCount]),
            io:format("(serv3) New instance created with PID = ~p~n", [NewPid]),
            exit(normal);  % Cleanly terminate old process
        {error, Reason} ->
            io:format("(serv3) Error: ~p~n", [Reason]),
            serv3(UnhandledCount);
        halt ->
            io:format("(serv3) Halting... Total unhandled messages: ~p~n", [UnhandledCount]);
        Other ->
            io:format("(serv3) Not handled: ~p~n", [Other]),
            serv3(UnhandledCount + 1)
    end.
