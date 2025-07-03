% ============================================
% check if a position is under attack
% ============================================


% find_king: find the position of king for given color
find_king(Position, Color, KingPos) :-
	get_half(Position, half_position(_,_,_,_,_,[KingPos],_,_), Color).

% check if position is attacked by enemy pawn
is_attacked_by_pawn(Pos, Color, Pawns) :-
    (
        Color = white ->
        (
            (
                PawnPos is Pos - 7,  % diagonal left attack
                Direction is PawnPos - Pos,
                valid_field(PawnPos),
                not(crosses_edge(Pos, PawnPos, Direction)),
                member(PawnPos, Pawns)
            ;
                PawnPos is Pos - 9,  % diagonal right attack
                Direction is PawnPos - Pos,
                valid_field(PawnPos),
                not(crosses_edge(Pos, PawnPos, Direction)),
                member(PawnPos, Pawns)
            )
        )
    ;
        Color = black ->
        (
            (
                PawnPos is Pos + 7,  % diagonal right attack
                Direction is PawnPos - Pos,
                valid_field(PawnPos),
                not(crosses_edge(Pos, PawnPos, Direction)),
                member(PawnPos, Pawns)
            ;
                PawnPos is Pos + 9,  % diagonal left attack
                Direction is PawnPos - Pos,
                valid_field(PawnPos),
                not(crosses_edge(Pos, PawnPos, Direction)),
                member(PawnPos, Pawns)
            )
        )
    ).  


is_attacked_by_knight(Pos, _Color, Knights) :-
    % Generate all possible knight move offsets
    KnightDirections = [15, 17, -15, -17, 6, 10, -6, -10],
    % Check each potential knight position
    member(Direction, KnightDirections),
    KnightPos is Pos + Direction,
    valid_field(KnightPos),
    not(crosses_edge(Pos, KnightPos, Direction)),
    member(KnightPos, Knights).

is_attacked_by_king(Pos, _Color, Kings) :-
    Kings = [KingPos],
    % Generate all possible king move directions/offsets
    KingDirections = [1, -1, 8, -8, 9, 7, -7, -9],
    % Check each potential king position
    member(Direction, KingDirections),
    KingPos is Pos + Direction,
    valid_field(KingPos),
    not(crosses_edge(Pos, KingPos, Direction)).

multiple_steps_to_enemy(Field,Direction,Next,Color,Position,BoardList):-
	invert(Color,FriendColor),
	one_step(Field,Direction,Next,FriendColor,Position,BoardList),
	nth0(Next, BoardList, [_, Color]),
	!.
multiple_steps_to_enemy(Field,Direction,Next,Color,Position,BoardList):-
	invert(Color,FriendColor),
	one_step(Field,Direction,FieldNew,FriendColor,Position,BoardList),
	multiple_steps_to_enemy(FieldNew,Direction,Next,Color,Position,BoardList),!.

inverse_long_move(Type, From, Color, Position, Direction, To, BoardList) :-
	piece_direction(Type, Direction),
	multiple_steps_to_enemy(From, Direction, To, Color, Position, BoardList).

is_attacked_on_line(Pos, Color, Position, Rooks, Bishops, Queens, BoardList) :- 
    inverse_long_move(queen, Pos, Color, Position, Direction, To, BoardList),
    (
        member(Direction, [7, -7, 9, -9]) ->
            (member(To, Bishops) ; member(To, Queens))
    ;
        member(Direction, [-1, 1, 8, -8]) ->
            (member(To, Rooks) ; member(To, Queens))
    ).


% main predicate to check if a position is under attack
is_under_attack(Pos, Color, Position, BoardList) :-
	invert(Color, EnemyColor),
	get_half(Position, half_position(Pawns, Rooks, Knights, Bishops, Queens, Kings, _, _), EnemyColor),
	(   is_attacked_by_pawn(Pos, EnemyColor, Pawns)
	;   is_attacked_by_knight(Pos, EnemyColor, Knights)
	;  	is_attacked_by_king(Pos, EnemyColor, Kings)
	;   is_attacked_on_line(Pos, EnemyColor, Position, Rooks, Bishops, Queens, BoardList)
	).

% check if king of given color is in check
in_check(Position, Color, BoardList) :-
	find_king(Position, Color, KingPos),
	is_under_attack(KingPos, Color, Position, BoardList).

% ============================================
% attack data
% ============================================

% inCheck, inDoubleCheck, pinExist, checkRay, 
% pinRay, opponentKnightAttacks, opponentAttackMapNoPawns
% opponentAttackMap, opponentPawnAttackMap, opponentSlidingAttackMap

generate_attack_data(Board, BoardList, AttackData) :- 
    AttackData = attack_data(
        InCheck, 
        InDoubleCheck, 
        PinExist, 
        CheckRay, 
        PinRay, 
        OpponentKnightAttacks, 
        OpponentAttackMapNoPawns,
        OpponentAttackMap, 
        OpponentPawnAttackMap, 
        OpponentSlidingAttackMap
    ),
    calculate_attack_data(Board, BoardList, AttackData).

calculate_attack_data(board(Position, Color, _), BoardList, attack_data(InCheck, InDoubleCheck, PinExist, CheckRay, PinRay, OpponentKnightAttacks, OpponentAttackMapNoPawns, OpponentAttackMap, OpponentPawnAttackMap, OpponentSlidingAttackMap)) :-
    
    gen_sliding_attack_map(board(Position, Color, _), BoardList, OpponentSlidingAttackMap).


gen_sliding_attack_map(board(Position, Color, _), BoardList, SlidingAttackMap) :-
    invert(Color, EnemyColor),
    get_half(Position, half_position(_, Rooks, _, Bishops, Queens, _, _, _), EnemyColor),
    
    % Generate attack map for orthogonal pieces (rooks and queens)
    append(Rooks, Queens, OrthogonalPieces),
    write('Orthogonal Pieces: '), write(OrthogonalPieces), nl,
    gen_sliding_attack_map_for_orthogonal(OrthogonalPieces, BoardList, Color, OrthogonalAttackMap),

    write('Orthogonal Attack Map: '), write(OrthogonalAttackMap), nl
    append(Bishops, Queens, DiagonalPieces),
    gen_sliding_attack_map_for_diagonal(DiagonalPieces, BoardList, Color, DiagonalAttackMap),

    % Combine both attack maps
    SlidingAttackMap is OrthogonalAttackMap \/ DiagonalAttackMap.

% Generate attack map for orthogonal pieces (rooks and queens)
gen_sliding_attack_map_for_orthogonal(Pieces, BoardList, Color, SlidingAttackMap) :-
    go_sliding(Pieces, newpiece, 8, BoardList, Color, 0, SlidingAttackMap1),
    go_sliding(Pieces, newpiece, -8, BoardList, Color, SlidingAttackMap1, SlidingAttackMap2),
    go_sliding(Pieces, newpiece, -1, BoardList, Color, SlidingAttackMap2, SlidingAttackMap3),
    go_sliding(Pieces, newpiece, 1,  BoardList, Color, SlidingAttackMap3, SlidingAttackMap).

gen_sliding_attack_map_for_diagonal(Pieces, BoardList, Color, SlidingAttackMap) :-
    go_sliding(Pieces, newpiece, 7, BoardList, Color, 0, SlidingAttackMap1),
    go_sliding(Pieces, newpiece, -7, BoardList, Color, SlidingAttackMap1, SlidingAttackMap2),
    go_sliding(Pieces, newpiece, 9, BoardList, Color, SlidingAttackMap2, SlidingAttackMap3),
    go_sliding(Pieces, newpiece, -9,  BoardList, Color, SlidingAttackMap3, SlidingAttackMap).


go_sliding([Piece|Pieces], newpiece, Direction, BoardList, Color, SlidingAttackMap, NewSlidingAttackMap) :- 
    From is Piece + Direction,
    go_sliding(Pieces, From, Direction, BoardList, Color, SlidingAttackMap, NewSlidingAttackMap)
    , !.

go_sliding([], _, _, _, _, SlidingAttackMap, SlidingAttackMap).

go_sliding(PieceList, From, Direction, BoardList, Color, SlidingAttackMap, NewSlidingAttackMap) :-
    From \= newpiece,
    opposite_direction(Direction, OppositeDirection),
    (   valid_field(From), move_direction(From, OppositeDirection)
    ->  To is From + Direction,
        write(From), nl,
        AccSlidingAttackMap is SlidingAttackMap \/ (1 << From),
        (   nth0(From, BoardList, [Type, PieceColor])
        ->  (   (Type = king, PieceColor = Color)
            ->  go_sliding(PieceList, To, Direction, BoardList, Color, AccSlidingAttackMap, NewSlidingAttackMap)
            ;   go_sliding(PieceList, newpiece, Direction, BoardList, Color, AccSlidingAttackMap, NewSlidingAttackMap)
            )
        ;   go_sliding(PieceList, To, Direction, BoardList, Color, AccSlidingAttackMap, NewSlidingAttackMap)
        )
    ;   go_sliding(PieceList, newpiece, Direction, BoardList, Color, SlidingAttackMap, NewSlidingAttackMap)
    ), !.
go_sliding([], newpiece, _, _, _, SlidingAttackMap, SlidingAttackMap).

% ...existing code...

