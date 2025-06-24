% =================================
% History management and threefold repetition
% =================================

:- dynamic history/1.
:- dynamic undo/0.
:- dynamic undo_move/0.

undo :- undo_move.

% Undo last move
undo_move :-
    history([_, board(PreviousPosition, PreviousColor, PreviousCounter)|RestHistory]),
    retract(history([_, board(PreviousPosition, PreviousColor, PreviousCounter)|RestHistory])),
    asserta(history([board(PreviousPosition, PreviousColor, PreviousCounter)|RestHistory])),
    retractall(board(_,_,_)),
    asserta(board(PreviousPosition, PreviousColor, PreviousCounter)).

% Initialize history with starting board state
init_history(Position, Color) :-
    retractall(history(_)),
    asserta(history([board(Position, Color, 0)])).

% Add board state to history
add_to_history(Position, Color, Counter) :-
    history(HistoryList),
    retract(history(HistoryList)),
    asserta(history([board(Position, Color, Counter)|HistoryList])).

% Check for threefold repetition
is_threefold_repetition(Position, Color) :-
    history(HistoryList),
    count_occurrences(board(Position, Color, _), HistoryList, Count),
    Count >= 3.

% Count occurrences of a board state in history
count_occurrences(board(Position, Color, _), HistoryList, Count) :-
    findall(1, member(board(Position, Color, _), HistoryList), Occurrences),
    length(Occurrences, Count).



% Check if undo is possible
can_undo :-
    history([_Current, _Previous|_]).
	
