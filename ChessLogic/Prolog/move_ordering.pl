quicksort([X|Xs],Ys) :-
    partition(Xs,X,Left,Right),
    quicksort(Left,Ls),
quicksort(Right,Rs),
    append(Ls,[X|Rs],Ys).
quicksort([],[]).

partition([X|Xs],Y,[X|Ls],Rs) :-
    compare_move(X, Y), partition(Xs, Y, Ls, Rs),!.
partition([X|Xs],Y,Ls,[X|Rs]) :-
    partition(Xs,Y,Ls,Rs),!.
partition([],_Y,[],[]).

append([],Ys,Ys).
append([X|Xs],Ys,[X|Zs]) :- append(Xs,Ys,Zs).

convert_captured_piece_to_value(CapturedPiece, Value) :-
    (   var(CapturedPiece) -> Value = 0
    ;   CapturedPiece = none -> Value = 0
    ;   CapturedPiece = pawn -> Value = 1
    ;   CapturedPiece = knight -> Value = 3
    ;   CapturedPiece = bishop -> Value = 3
    ;   CapturedPiece = rook -> Value = 5
    ;   CapturedPiece = queen -> Value = 9
    ).
%Less or equal =<
compare_move(MoveX, MoveY) :-
    MoveX = move(FromX, ToX, CapturedPieceX, PromotionPieceX),
    MoveY = move(FromY, ToY, CapturedPieceY, PromotionPieceY) ->
    convert_captured_piece_to_value(CapturedPieceX, ValueX),
    convert_captured_piece_to_value(CapturedPieceY, ValueY),
    ValueX =< ValueY.