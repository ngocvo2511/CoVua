% =================================
% History management and threefold repetition
% =================================
:- dynamic history/2.
:- dynamic history_board/4.
:- dynamic quick_history/1.

undo :- undo_move.

% Undo last move
undo_move :-
    history(Board, Move),
    not(Move = move(64, 64, none, none, none)),
    retract(history(Board, Move)),
    history(NewBoard, _NewMove),
    retract(board(_,_,_,_)),
    asserta(NewBoard),
    retract(quick_history(_)).

% Initialize history with starting board state
init_history(Position, Color, Key) :-
    retractall(history(_,_)),
    retractall(quick_history(_)),
    asserta(history(board(Position, Color, 0, Key), move(64, 64, none, none, none))),
    asserta(quick_history(Key)).

% Add board state to history
add_to_history(Position, Color, Counter, Key, Move) :-
    asserta(history(board(Position, Color, Counter, Key), Move)),
    asserta(quick_history(Key)).

get_history_moves(Moves) :-
    findall(Move, history(_, Move), ReversedMoves),
    reverse(ReversedMoves, Moves).

set_history_moves(Moves) :-
    retractall(history(_, _)),
    retractall(board(_, _, _, _)),
    retractall(quick_history(_)),
    initial_pos(StartPosition),
    position_to_board_list(StartPosition, BoardList),
    zobrist_hash_from_board_list(BoardList, StartPosition, white, Key),
    asserta(history(board(StartPosition, white, 0, Key), move(64, 64, none, none, none))), % Dummy starting move
    asserta(history_board(StartPosition, white, 0, Key)), % Initialize the board state
    asserta(quick_history(Key)), % Initialize quick history
    forall(
        member(Move, Moves), 
        process_and_add_move(Move)
    ),
    % Set the final board state
    history_board(FinalPosition, FinalColor, FinalCounter, FinalKey),
    retract(history_board(_, _, _, _)),
    asserta(board(FinalPosition, FinalColor, FinalCounter, FinalKey)).

% Helper predicate to process each move
process_and_add_move(Move) :-
    (   Move == move(64, 64, none, none, none)
    ->  % Skip the dummy starting move
        true
    ;   % Process the actual move
        history_board(Position, Color, Counter, Key),
        Move = move(From, To, MovedPiece, CapturedPiece, PromotedPiece), 
        position_to_board_list(Position, BoardList),
        Board = board(Position, Color, Counter, Key),
        generate_attack_data(Board, BoardList, AttackData),
        simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, BoardList, AttackData, Key, NewKey),
        update_fifty_move_counter(From, To, Position, Color, Counter, NewCounter, BoardList, AttackData),
        invert(Color, NewColor),
        retract(history_board(_, _, _, _)),
        asserta(history_board(NewPosition, NewColor, NewCounter, NewKey)),
        asserta(history(board(NewPosition, NewColor, NewCounter, NewKey), Move)),
        asserta(quick_history(NewKey))
    ).

% Check for threefold repetition
is_threefold_repetition(Position, Color) :-
    findall(1, history(board(Position, Color, _, _), _), Occurrences),
    length(Occurrences, Count),
    Count >= 3.    
is_repeated(Key) :-
    findall(1, quick_history(Key), Occurrences),
    length(Occurrences, Count),
    Count > 1.
