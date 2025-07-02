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

%Less or equal =<
compare_move(MoveX, MoveY) :-
    MoveX = move(FromX, ToX, MovedPieceX, CapturedPieceX, PromotedPieceX),
    MoveY = move(FromY, ToY, MovedPieceY, CapturedPieceY, PromotedPieceY) ->
    
    piece_value(CapturedPieceX, CapturedPieceValueX),
    piece_value(CapturedPieceY, CapturedPieceValueY),

    piece_value(MovedPieceX, MovedPieceValueX),
    piece_value(MovedPieceY, MovedPieceValueY),

    (CapturedPieceValueX = 0 -> CaptureValueX = 0 ; CaptureValueX = 10 * CapturedPieceValueX - MovedPieceValueX),
    (CapturedPieceValueY = 0 -> CaptureValueY = 0 ; CaptureValueY = 10 * CapturedPieceValueY - MovedPieceValueY),

    piece_value(PromotedPieceX, PromotedPieceValueX),
    piece_value(PromotedPieceY, PromotedPieceValueY),

    ValueX is CaptureValueX + PromotedPieceValueX,
    ValueY is CaptureValueY + PromotedPieceValueY,

    ValueX =< ValueY.