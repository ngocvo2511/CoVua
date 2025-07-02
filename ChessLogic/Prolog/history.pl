% =================================
% History management and threefold repetition
% =================================
undo :- undo_move.

% Undo last move
undo_move :-
    history(Board, Move),
    not(Move = move(64, 64, none, none, none)),
    retract(history(Board, Move)),
    history(NewBoard, _NewMove),
    retract(board(_,_,_)),
    asserta(NewBoard).

% Initialize history with starting board state
init_history(Position, Color) :-
    retractall(history(_,_)),
    asserta(history(board(Position, Color, 0), move(64, 64, none, none, none))).

% Add board state to history
add_to_history(Position, Color, Counter, Move) :-
    asserta(history(board(Position, Color, Counter), Move)).

get_history_moves(Moves) :-
    findall(Move, history(_, Move), ReversedMoves),
    reverse(ReversedMoves, Moves).

set_history_moves(Moves) :-
    retractall(history(_, _)),
    retractall(board(_, _, _)),
    initial_pos(StartPosition),
    asserta(history(board(StartPosition, white, 0), move(64, 64, none, none, none))), % Dummy starting move
    asserta(history_board(StartPosition, white, 0)), % Initialize the board state
    forall(
        member(Move, Moves), 
        process_and_add_move(Move)
    ),
    % Set the final board state
    history_board(FinalPosition, FinalColor, FinalCounter),
    asserta(board(FinalPosition, FinalColor, FinalCounter)).

% Helper predicate to process each move
process_and_add_move(Move) :-
    (   Move == move(64, 64, none, none, none)
    ->  % Skip the dummy starting move
        true
    ;   % Process the actual move
        history_board(Position, Color, Counter),
        Move = move(From, To, MovedPiece, CapturedPiece, PromotedPiece), 
        position_to_board_list(Position, BoardList),
        simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, BoardList),
        update_fifty_move_counter(From, To, Position, Color, Counter, NewCounter, BoardList),
        invert(Color, NewColor),
        retract(history_board(_, _, _)),
        asserta(history_board(NewPosition, NewColor, NewCounter)),
        asserta(history(board(NewPosition, NewColor, NewCounter), Move))
    ).

% Check for threefold repetition
is_threefold_repetition(Position, Color) :-
    findall(1, history(board(Position, Color, _), _), Occurrences),
    length(Occurrences, Count),
    Count >= 3.    

	
