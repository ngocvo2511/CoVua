% =================================
% History management and threefold repetition
% =================================

undo :- undo_move.

% Undo last move
undo_move :-
    history(Board),
    retract(history(Board)),
    (not(history(NewBoard)) -> asserta(Board); NewBoard = Board),
    retract(board(_,_,_)),
    asserta(NewBoard).

% Initialize history with starting board state
init_history(Position, Color) :-
    retractall(history(_)),
    asserta(history(board(Position, Color, 0))).

% Add board state to history
add_to_history(Position, Color, Counter) :-
    asserta(history(board(Position, Color, Counter))).

set_new_history(HistoryList) :-
    retractall(history(_)),
    retractall(board(_,_,_)),
    set_full_history(HistoryList).

set_full_history([Board|Rest]) :-
    set_full_history(Rest),
    asserta(Board),
    asserta(history(Board)).

set_full_history([]).

get_full_history(HistoryList) :-
    findall(Board, history(Board), HistoryList).

% Check for threefold repetition
is_threefold_repetition(Position, Color) :-
    findall(1, history(board(Position, Color, _)), Occurrences),
    length(Occurrences, Count),
    Count >= 3.    

	
