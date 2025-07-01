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
    
    piece_value(CapturedPieceX, CaptureValueX),
    piece_value(CapturedPieceY, CaptureValueY),

    piece_value(MovedPieceX, MovedValueX),
    piece_value(MovedPieceY, MovedValueY),

    piece_value(PromotedPieceX, PromotedValueX),
    piece_value(PromotedPieceY, PromotedValueY),

    ValueX is (10 * CaptureValueX - MovedValueX) + PromotedValueX,
    ValueY is (10 * CaptureValueY - MovedValueY) + PromotedValueY,

    ValueX =< ValueY.