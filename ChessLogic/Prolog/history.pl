% =================================
% History management and threefold repetition
% =================================

% Initialize history with starting board state
init_history(Position, Color) :-
    retractall(history(_)),
    asserta(history([board(Position, Color)])).

% Add board state to history
add_to_history(Position, Color) :-
    history(HistoryList),
    retract(history(HistoryList)),
    asserta(history([board(Position, Color)|HistoryList])).

% Check for threefold repetition
is_threefold_repetition(Position, Color) :-
    history(HistoryList),
    count_occurrences(board(Position, Color), HistoryList, Count),
    Count >= 3.

% Count occurrences of a board state in history
count_occurrences(_, [], 0).
count_occurrences(BoardState, [BoardState|Rest], Count) :-
    count_occurrences(BoardState, Rest, RestCount),
    Count is RestCount + 1.
count_occurrences(BoardState, [Other|Rest], Count) :-
    BoardState \= Other,
    count_occurrences(BoardState, Rest, Count).

% Undo last move
undo_move(PreviousPosition, PreviousColor) :-
    history([_, board(PreviousPosition, PreviousColor)|RestHistory]),
    retract(history([_, board(PreviousPosition, PreviousColor)|RestHistory])),
    asserta(history([board(PreviousPosition, PreviousColor)|RestHistory])),
    retractall(board(_,_)),
    asserta(board(PreviousPosition, PreviousColor)).

% Check if undo is possible
can_undo :-
    history([_Current, _Previous|_]).
	
undo :- undo_move(_PreviousPosition, _PreviousColor).

% Get current board state from history
get_current_board(Position, Color) :-
    history([board(Position, Color)|_]).