% =================================
% Minimax AI
% =================================

% Initialize default depth if not set
init_minimax :-
    (depth(_) -> true ; asserta(depth(3))).

% Main bot move predicate - call this for computer turn
bot_move :-
    init_minimax,
    board(Position, Color, _),
    depth(Depth),
    minimax(Position, Color, Depth, BestMove, _BestValue),
    BestMove = [From, To],
    place_piece(From, To),
    write('Bot played: '), write(From), write(' to '), write(To), nl.

% Main minimax entry point
minimax(Position, Color, Depth, BestMove, BestValue) :-
    worst_value(white, Alpha),
    worst_value(black, Beta),
    minimax_ab(Position, Color, Depth, Alpha, Beta, BestMove, BestValue).

% Minimax with alpha-beta pruning
minimax_ab(Position, Color, 0, _Alpha, _Beta, [0,0], Value) :-
    evaluate_position(Position, Color, Value), !.

minimax_ab(Position, Color, Depth, Alpha, Beta, BestMove, BestValue) :-
    Depth > 0,
    get_all_legal_moves(Color, Position, Moves),
    (   Moves = [] ->
        evaluate_position(Position, Color, BestValue),
        BestMove = [0,0]
    ;   worst_value(Color, InitialBest),
        evaluate_moves(Moves, Position, Color, Depth, Alpha, Beta, 
                      [0,0], InitialBest, BestMove, BestValue)
    ).

% Evaluate all moves and find the best one
evaluate_moves([], _Position, _Color, _Depth, _Alpha, _Beta, 
               CurrentBest, CurrentValue, CurrentBest, CurrentValue).

evaluate_moves([Move|RestMoves], Position, Color, Depth, Alpha, Beta,
               CurrentBest, CurrentValue, BestMove, BestValue) :-
    Move = [From, To],
    simulate_move(From, To, Color, Position, NewPosition),
    invert(Color, OpponentColor),
    NewDepth is Depth - 1,
    minimax_ab(NewPosition, OpponentColor, NewDepth, Alpha, Beta, _OpponentMove, Value),
    
    % Update best move if this move is better
    (   is_better_move(Color, Value, CurrentValue) ->
        NewBest = Move,
        NewValue = Value
    ;   NewBest = CurrentBest,
        NewValue = CurrentValue
    ),
    
    % Alpha-beta pruning
    update_alpha_beta(Color, NewValue, Alpha, Beta, NewAlpha, NewBeta),
    (   should_prune(Color, NewValue, Alpha, Beta) ->
        BestMove = NewBest,
        BestValue = NewValue
    ;   evaluate_moves(RestMoves, Position, Color, Depth, NewAlpha, NewBeta,
                      NewBest, NewValue, BestMove, BestValue)
    ).

% Check if a move is better based on the color
is_better_move(white, Value, CurrentValue) :-
    Value > CurrentValue.
is_better_move(black, Value, CurrentValue) :-
    Value < CurrentValue.

% Update alpha-beta values
update_alpha_beta(white, Value, Alpha, Beta, NewAlpha, Beta) :-
    NewAlpha is max(Alpha, Value).
update_alpha_beta(black, Alpha, Beta, Value, Alpha, NewBeta) :-
    NewBeta is min(Beta, Value).

% Check if we should prune
should_prune(white, Value, _Alpha, Beta) :-
    Value >= Beta.
should_prune(black, Value, Alpha, _Beta) :-
    Value =< Alpha.

% Helper predicates for values
worst_value(white, -10000).
worst_value(black, 10000).

% Test minimax functionality
test_minimax :-
    set_position(begin),
    board(Position, Color, _),
    asserta(depth(2)),
    write('Testing minimax with position: '), write(Position), nl,
    write('Current player: '), write(Color), nl,
    minimax(Position, Color, 2, BestMove, BestValue),
    write('Best move found: '), write(BestMove), nl,
    write('Best value: '), write(BestValue), nl.

