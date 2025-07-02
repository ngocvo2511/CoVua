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
    (
        KnightPos is Pos + 15,
        Direction is KnightPos - Pos,
        valid_field(KnightPos),
        not(crosses_edge(Pos, KnightPos, Direction)),
        member(KnightPos, Knights)
    ;
        KnightPos is Pos + 17,
        Direction is KnightPos - Pos,
        valid_field(KnightPos),
        not(crosses_edge(Pos, KnightPos, Direction)),
        member(KnightPos, Knights)
    ;
        KnightPos is Pos - 15,
        Direction is KnightPos - Pos,
        valid_field(KnightPos),
        not(crosses_edge(Pos, KnightPos, Direction)),
        member(KnightPos, Knights)
    ;
        KnightPos is Pos - 17,
        Direction is KnightPos - Pos,
        valid_field(KnightPos),
        not(crosses_edge(Pos, KnightPos, Direction)),
        member(KnightPos, Knights)
    ;
        KnightPos is Pos + 6,
        Direction is KnightPos - Pos,
        valid_field(KnightPos),
        not(crosses_edge(Pos, KnightPos, Direction)),
        member(KnightPos, Knights)
    ;
        KnightPos is Pos + 10,
        Direction is KnightPos - Pos,
        valid_field(KnightPos),
        not(crosses_edge(Pos, KnightPos, Direction)),
        member(KnightPos, Knights)
    ;
        KnightPos is Pos - 6,
        Direction is KnightPos - Pos,
        valid_field(KnightPos),
        not(crosses_edge(Pos, KnightPos, Direction)),
        member(KnightPos, Knights)
    ;
        KnightPos is Pos - 10,
        Direction is KnightPos - Pos,
        valid_field(KnightPos),
        not(crosses_edge(Pos, KnightPos, Direction)),
        member(KnightPos, Knights)
    ).

is_attacked_by_king(Pos, _Color, Kings) :-
	Kings = [KingPos],
	(
		KingPos is Pos + 1, valid_field(KingPos), Direction is KingPos - Pos, not(crosses_edge(Pos, KingPos, Direction)) ; % right
		KingPos is Pos - 1, valid_field(KingPos), Direction is KingPos - Pos, not(crosses_edge(Pos, KingPos, Direction)) ; % left
		KingPos is Pos + 8, valid_field(KingPos), Direction is KingPos - Pos, not(crosses_edge(Pos, KingPos, Direction)) ; % up
		KingPos is Pos - 8, valid_field(KingPos), Direction is KingPos - Pos, not(crosses_edge(Pos, KingPos, Direction)) ; % down
		KingPos is Pos + 9, valid_field(KingPos), Direction is KingPos - Pos, not(crosses_edge(Pos, KingPos, Direction)) ; % up-right
		KingPos is Pos + 7, valid_field(KingPos), Direction is KingPos - Pos, not(crosses_edge(Pos, KingPos, Direction)) ; % up-left
		KingPos is Pos - 7, valid_field(KingPos), Direction is KingPos - Pos, not(crosses_edge(Pos, KingPos, Direction)) ; % down-left
		KingPos is Pos - 9, valid_field(KingPos), Direction is KingPos - Pos, not(crosses_edge(Pos, KingPos, Direction))    % down-right
	).


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
