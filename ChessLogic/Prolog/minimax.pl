% =================================
% Minimax AI
% =================================

% Initialize default depth if not set
init_minimax :-
    retractall(count(_)),
    asserta(count(0)),
    (depth(_) -> true ; asserta(depth(3))),
    (stack(_, _, _) -> true ; asserta(stack(_, _, 0))).

% Main bot move predicate - call this for computer turn

update_depth(Depth, NewDepth) :-
    NewDepth is Depth-1,!.	

update_alpha_beta(Color,Alpha,NewAlpha,Beta,NewBeta) :-
    get(_,Value),
    (   Color = white ->
        NewAlpha is max(Alpha, Value),
        NewBeta = Beta
    ;   Color = black ->
        NewBeta is min(Beta, Value),
        NewAlpha = Alpha
    ).


bot_move(From, To, Status) :-
    init_minimax,
    board(Position, Color, Counter),
    depth(Depth),
    losing_value(white,Alpha),
	losing_value(black,Beta),
    minimax(Position, Color, Counter, Move, Depth, _Value, Alpha, Beta),
    count(Count),
    write('Count: '), write(Count), nl,
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
    update_alpha_beta(Color, Alpha, NewAlpha, Beta, NewBeta),

    get_all_legal_moves(Position, Color, MoveList),
    %write('Depth: '), write(Depth), nl, write('MoveList: '), write(MoveList), nl,
    (   MoveList = [] -> 
        count(Count),
        retract(count(Count)),
        NewCount is Count + 1,
        asserta(count(NewCount)),
        Move = move(64, 64, none),
        (   in_check(Position, Color) -> 
            minimax(_Position, Color, _Counter, Move, checkmate, Value, NewAlpha, NewBeta)
        ;   
            minimax(_Position, _Color, _Counter, Move, stalemate, Value, NewAlpha, NewBeta)
        )
    ;
        simulate_new_position_from_move_list(MoveList, Move, Color, Position, NewPosition),
        minimax(NewPosition, Op, Counter, _Move, NewDepth, Value, NewAlpha, NewBeta)
    ),    
    compare_move(Move, Value, Color),    
    prune(Value, Color, Alpha, Beta),
    !, fail.

compare_move(Move, Value, Color) :-
    get(OldMove, OldValue),
    (   (Color = white, OldValue >= Value) ->
        true  
    ;   (Color = black, OldValue =< Value) ->
        true 
    ;   replace(Move, Value)
    ),
    (
        OldMove = move(64, 64, none) -> replace(Move, Value)
    ;   true
    ).

prune(Value, Color, Alpha, Beta) :-
    (   (Color = white, Value > Beta) -> true
    ;   (Color = black, Value < Alpha) -> true
    ;   false
    ).

minimax(_Position, _Color, _Counter, move(64, 64, none), stalemate, Value, _Alpha, _Beta) :-
    Value is 0, !.

minimax(_Position, Color, _Counter, move(64, 64, none), checkmate, Value, _Alpha, _Beta) :-
    losing_value(Color, Value),!.

minimax(Position, _Color, _Counter, move(64, 64, none), 0, Value, _Alpha, _Beta) :-
count(Counter),
    retract(count(Counter)),
    NewCounter is Counter + 1,
    asserta(count(NewCounter)),
    %score(Position, Color, Counter, Value), 
    Position = position(WhiteHalf, BlackHalf),
    score_half(WhiteHalf, white, ValueWhite),
    score_half(BlackHalf, black, ValueBlack),
    Value is ValueWhite - ValueBlack, !.

minimax(Position, Color, Counter, Move, Depth, Value, Alpha, Beta) :-
    count(Count),
    retract(count(Count)),
    NewCount is Count + 1,
    asserta(count(NewCount)),
    (  losing_value(Color, Worst),
        push(move(64, 64, none), Worst),
        not(get_best(Position, Color, Counter, Depth, Alpha, Beta)),
        pop(Move, Value)
    ), !.


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
    ).

replace(Move, Value) :-
    top_depth(Depth),
    retract(stack(_, _, Depth)),
    asserta(stack(Move, Value, Depth)), !.