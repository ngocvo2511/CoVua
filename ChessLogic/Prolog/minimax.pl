% =================================
% Minimax AI
% =================================

% Initialize default depth if not set
init_minimax :-
    (depth(_) -> true ; asserta(depth(3))),
    (stack(_, _, _) -> true ; asserta(stack(_, _, 0))).

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
    depth(Depth),
    losing_value(white,Alpha),
	losing_value(black,Beta),
    asserta(count(0)),
    minimax(Position, Color, Counter, Move, Depth, _Value, Alpha, Beta),
    retract(count(_Count)),
    %write('Depth: '), write(Depth), write(' Count: '), write(Count), nl,
    Move = move(From, To, PromotionPiece),
    place_piece(From, To, Status, PromotionPiece),
    % Get the new game state after the move
    board(NewPosition, NewColor, NewCounter),
    check_game_status(NewPosition, NewColor, NewCounter, Status).

simulate_new_position_from_move_list([Move|_], Move, Color, Position, NewPosition) :-
    Move = move(From, To, PromotionPiece),
    simulate_move(From, To, Color, Position, NewPosition, PromotionPiece).
simulate_new_position_from_move_list([_|Rest], Move, Color, Position, NewPosition) :-
    simulate_new_position_from_move_list(Rest, Move, Color, Position, NewPosition).
% simulate_new_position_from_move_list([], _, _, Position, Position, _).

get_best(Position, Color, Counter, Depth, Alpha, Beta) :-
    invert(Color, Op),
    update_depth(Depth, NewDepth),
    %write('Depth: '), write(Depth), write(' Moves: '), write(MoveList), nl,
    generate_move(Move, Color, Position, NewPosition),
    update_alpha_beta(Color, Alpha, NewAlpha, Beta, NewBeta),
    (   Move = move(64, 64, none) ->
        (   in_check(Position, Color) ->
            losing_value(Color, Value)
        ;   Value is 0
        )
    ;   minimax(NewPosition, Op, Counter, _Move, NewDepth, Value, NewAlpha, NewBeta)
    ),
    %(Depth = 3 -> write('New alpha: '), write(NewAlpha), nl, write('New beta: '), write(NewBeta), nl ; true),
    compare_move(Move, Value, Color),
    prune(Value, Color, Alpha, Beta),
    !,fail.

compare_move(Move, Value, Color) :-
    get(OldMove, OldValue),
    (   ((Color = white, OldValue < Value) ; (Color = black, OldValue > Value) ; OldMove = move(64, 64, none)) ->
        replace(Move, Value)
    ;   true
    ), !.

prune(Value, Color, Alpha, Beta) :-
    (Color = white, Value >= Beta);
    (Color = black, Value =< Alpha).

minimax(Position, _Color, _Counter, move(64, 64, none), 0, Value, _Alpha, _Beta) :-
    % for counting nodes at final depth for testing 
    %count(Count),
    %retract(count(Count)),
    %NewCount is Count + 1,
    %asserta(count(NewCount)),
    %score(Position, Color, Counter, Value), 
    Position = position(WhiteHalf, BlackHalf),
    score_half(WhiteHalf, white, ValueWhite),
    score_half(BlackHalf, black, ValueBlack),
    Value is ValueWhite - ValueBlack, !.

minimax(Position, Color, Counter, Move, Depth, Value, Alpha, Beta) :-
    %get_all_legal_moves(Position, Color, MoveList),
    %write(MoveList),nl,
    (   (is_threefold_repetition(Position, Color) ; is_fifty_move(Counter)) ->
        Value is 0
    ;
        losing_value(Color, Worst),
        push(move(64, 64, none), Worst),
        not(get_best(Position, Color, Counter, Depth, Alpha, Beta)),
        pop(Move, Value)
    ), 
!.


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