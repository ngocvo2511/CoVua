% Initialize default depth if not set
init_minimax :-
    (depth(_) -> true ; asserta(depth(3))),
    retractall(stack(_, _, _)), % Clear any existing stack
    asserta(stack(_, _, 0)).

update_depth(Depth, NewDepth) :-
    NewDepth is Depth-1, !.	

update_alpha_beta(Color,Alpha,NewAlpha,Beta,NewBeta) :-
    get(_,Value),
    (   Color = white ->
        NewAlpha is max(Alpha, Value),
        NewBeta = Beta
    ;   Color = black ->
        NewBeta is min(Beta, Value),
        NewAlpha = Alpha
    ).
       % write('New alpha: '), write(NewAlpha), nl,
       % write('New beta: '), write(NewBeta), nl.


bot_move(From, To, Status) :-
    init_minimax,
    board(Position, Color, Counter),
    Board = board(Position, Color, Counter),
    depth(Depth),
    losing_value(white,Alpha),
	losing_value(black,Beta),
    asserta(count(0)),
    minimax(Position, Color, Counter, Move, Depth, _Value, Alpha, Beta),
    retract(count(Count)),
    write(Count),nl,
    %write('Depth: '), write(Depth), write(' Count: '), write(Count), nl,
    Move = move(From, To, _MovedPiece, _CapturedPiece, PromotionPiece),
    place_piece(From, To, Status, PromotionPiece),
    % Get the new game state after the move
    board(NewPosition, NewColor, NewCounter),
    check_game_status(NewPosition, NewColor, NewCounter, Status).

simulate_new_position_from_move_list([Move|_], Move, Color, Position, NewPosition, BoardList, AttackData) :-
    Move = move(From, To, MovedPiece, CapturedPiece, PromotionPiece),
    simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotionPiece, BoardList, AttackData).
simulate_new_position_from_move_list([_|Rest], Move, Color, Position, NewPosition, BoardList, AttackData) :-
    simulate_new_position_from_move_list(Rest, Move, Color, Position, NewPosition, BoardList, AttackData).
simulate_new_position_from_move_list([], _, _, Position, _, _, _).

get_best(Position, Color, Counter, Depth, Alpha, Beta) :-
    invert(Color, Op),
    update_depth(Depth, NewDepth),
    %generate_move(Move, Color, Position, NewPosition),
    position_to_board_list(Position, BoardList),
    generate_attack_data(board(Position, Color, Counter), BoardList, AttackData),
    AttackData = attack_data(
        InCheck, 
        _InDoubleCheck, 
        _PinExist, 
        _CheckRay, 
        _PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        _OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),   

    get_all_pseudo_legal_moves(Position, Color, MoveList, BoardList, AttackData),
    quicksort(MoveList, SortedMoveList,AttackData),
    simulate_new_position_from_move_list(SortedMoveList, Move, Color, Position, NewPosition, BoardList, AttackData),
    NewBoard = board(NewPosition, Op, Counter),
    update_alpha_beta(Color, Alpha, NewAlpha, Beta, NewBeta),
    (   SortedMoveList = [] ->
        (   InCheck = false ->
            Value is 0
        ;   losing_value(Color, Value)
        )
    ;   (   %(NewDepth \= 0 ; (NewDepth = 0, Move = move(_,_,_,none,_))) ->
            minimax(NewPosition, Op, Counter, _Move, NewDepth, Value, NewAlpha, NewBeta)
        % ;   minimax_quiescence(NewPosition, Op, Counter, Value, NewAlpha, NewBeta)
        )
    ),
    compare_move(Move, Value, Color),
    prune(Value, Color, Alpha, Beta), !, fail.

compare_move(Move, Value, Color) :-
    get(OldMove, OldValue),
    (   ((Color = white, OldValue < Value) ; (Color = black, OldValue > Value) ; OldMove = move(64, 64, none, none, none)) ->
        replace(Move, Value)
    ;   true
    ), !.

prune(Value, Color, Alpha, Beta) :-
    (Color = white, Value >= Beta);
    (Color = black, Value =< Alpha).

minimax(Position, Color, Counter, move(64, 64, none, none, none), 0, Value, Alpha, Beta) :-
    % for counting nodes at final depth for testing
    count(Count),
    retract(count(Count)),
    NewCount is Count + 1,
    asserta(count(NewCount)),
    Position = position(WhiteHalf, BlackHalf),
    score_half(WhiteHalf, white, ValueWhite),
    score_half(BlackHalf, black, ValueBlack),
    Value is ValueWhite - ValueBlack, !.

minimax(Position, Color, Counter, Move, Depth, Value, Alpha, Beta) :-
    count(Count),
    retract(count(Count)),
    NewCount is Count + 1,
    asserta(count(NewCount)),
    (   (is_threefold_repetition(Position, Color) ; is_fifty_move(Counter)) ->
        Value is 0
    ;
        losing_value(Color, Worst),
        push(move(64, 64, none, none, none), Worst),
        not(get_best(Position, Color, Counter, Depth, Alpha, Beta)),
        pop(Move, Value)
    ), !.

minimax_quiescence(Position, Color, Counter, Value, Alpha, Beta) :-
    losing_value(Color, Worst),
    push(move(64, 64, none, none, none), Worst),
    not(get_best_quiescence(Position, Color, Counter, Alpha, Beta)),
    pop(Move, Value), !.

get_best_quiescence(Position, Color, Counter, Alpha, Beta) :-
    Position = position(WhiteHalf, BlackHalf),
    score_half(WhiteHalf, white, ValueWhite),
    score_half(BlackHalf, black, ValueBlack),
    Eval is ValueWhite - ValueBlack,
    compare_move(move(64, 64, none, none, none), Eval, Color),
    (prune(Eval, Color, Alpha, Beta) -> !, fail ; true),
    invert(Color, Op),
    position_to_board_list(Position, BoardList),
    generate_attack_data(board(Position, Color, Counter), BoardList, AttackData),
    AttackData = attack_data(
        InCheck, 
        _InDoubleCheck, 
        _PinExist, 
        _CheckRay, 
        _PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        _OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),   

    get_all_noisy_pseudo_legal_moves(Position, Color, MoveList, BoardList, AttackData),
    quicksort(MoveList, SortedMoveList,AttackData),
    simulate_new_position_from_move_list(SortedMoveList, Move, Color, Position, NewPosition, BoardList, AttackData),

    update_alpha_beta(Color, Alpha, NewAlpha, Beta, NewBeta),
    (   SortedMoveList = [] ->
        (   InCheck = false ->
            Value is 0
        ;   losing_value(Color, Value)
        )
    ;   minimax_quiescence(NewPosition, Op, Counter, Value, NewAlpha, NewBeta)
    ),
    compare_move(Move, Value, Color),
    prune(Value, Color, Alpha, Beta), !, fail.


% =================================
% Minimax value stack
% =================================
push(Move, Value) :-
    top_depth(Depth),
    NewDepth is Depth + 1,
    asserta(stack(Move, Value, NewDepth)), !.
pop(Move,Value) :-
   top_depth(Depth),
   retract(stack(Move, Value, Depth)), !.

get(Move, Value) :-
    top_depth(Depth),
    stack(Move, Value, Depth), !.

top_depth(Depth) :-
    (   stack(_, _, Depth) -> true
    ;   Depth = 0
    ), !.

replace(Move, Value) :-
    top_depth(Depth),
    retract(stack(_, _, Depth)),
    asserta(stack(Move, Value, Depth)), !.