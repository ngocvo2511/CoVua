quicksort([X|Xs],Ys, AttackData) :-
    partition(Xs,X,Left,Right, AttackData),
    quicksort(Left,Ls, AttackData),
    quicksort(Right,Rs, AttackData),
    append(Ls,[X|Rs],Ys).
quicksort([],[],_).

partition([X|Xs],Y,[X|Ls],Rs, AttackData) :-
    compare_move_for_sorting(X, Y, AttackData), partition(Xs, Y, Ls, Rs, AttackData),!.
partition([X|Xs],Y,Ls,[X|Rs], AttackData) :-
    partition(Xs,Y,Ls,Rs, AttackData),!.
partition([], _Y, [], [], _).

append([],Ys,Ys).
append([X|Xs],Ys,[X|Zs]) :- append(Xs,Ys,Zs).

%Less or equal =<
compare_move_for_sorting(MoveX, MoveY, AttackData) :-
    AttackData = attack_data(
        _InCheck, 
        _InDoubleCheck, 
        _PinExist, 
        _CheckRay, 
        _PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        _OpponentAttackMap, 
        OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
    MoveX = move(_FromX, ToX, MovedPieceX, CapturedPieceX, PromotedPieceX),
    MoveY = move(_FromY, ToY, MovedPieceY, CapturedPieceY, PromotedPieceY) ->

    piece_value(CapturedPieceX, CapturedPieceValueX),
    piece_value(CapturedPieceY, CapturedPieceValueY),

    piece_value(MovedPieceX, MovedPieceValueX),
    piece_value(MovedPieceY, MovedPieceValueY),

    (CapturedPieceValueX = 0 -> CaptureValueX = 0 ; CaptureValueX = 10 * CapturedPieceValueX - MovedPieceValueX),
    (CapturedPieceValueY = 0 -> CaptureValueY = 0 ; CaptureValueY = 10 * CapturedPieceValueY - MovedPieceValueY),

    piece_value(PromotedPieceX, PromotedPieceValueX),
    piece_value(PromotedPieceY, PromotedPieceValueY),

    (((OpponentPawnAttackMap >> ToX) /\ 1) =:= 1 -> PenaltyValueX = 350 ; PenaltyValueX = 0),
    (((OpponentPawnAttackMap >> ToY) /\ 1) =:= 1 -> PenaltyValueY = 350 ; PenaltyValueY = 0),

    ValueX is CaptureValueX + PromotedPieceValueX - PenaltyValueX,
    ValueY is CaptureValueY + PromotedPieceValueY - PenaltyValueY,

    ValueX =< ValueY.