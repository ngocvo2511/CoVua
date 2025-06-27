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
			PawnPos is Pos - 7,  % diagonal left attack
			valid_field(PawnPos),
			not(crosses_edge(PawnPos, Pos, PawnPos - Pos)),
			member(PawnPos, Pawns)
		;   
			PawnPos is Pos - 9,  % diagonal right attack
			valid_field(PawnPos),
			not(crosses_edge(PawnPos, Pos, PawnPos - Pos)),
			member(PawnPos, Pawns)
		)
		;
		Color = black ->
		(
			PawnPos is Pos + 7,  % diagonal right attack
			valid_field(PawnPos),
			not(crosses_edge(PawnPos, Pos, PawnPos - Pos)),
			member(PawnPos, Pawns)
		;
			PawnPos is Pos + 9,  % diagonal left attack
			valid_field(PawnPos),
			not(crosses_edge(PawnPos, Pos, PawnPos - Pos)),
			member(PawnPos, Pawns)
		)
	).

is_attacked_by_knight(Pos, _Color, Knights) :-
	(
		KnightPos is Pos + 15, % L-shape move
		valid_field(KnightPos),
		not(crosses_edge(KnightPos, Pos, KnightPos - Pos)),
		member(KnightPos, Knights)
	;
		KnightPos is Pos + 17,
		valid_field(KnightPos),
		not(crosses_edge(KnightPos, Pos, KnightPos - Pos)),
		member(KnightPos, Knights)
	;
		KnightPos is Pos - 15,
		valid_field(KnightPos),
		not(crosses_edge(KnightPos, Pos, KnightPos - Pos)),
		member(KnightPos, Knights)
	;
		KnightPos is Pos - 17,
		valid_field(KnightPos),
		not(crosses_edge(KnightPos, Pos, KnightPos - Pos)),
		member(KnightPos, Knights)
	;
		KnightPos is Pos + 6,
		valid_field(KnightPos),
		not(crosses_edge(KnightPos, Pos, KnightPos - Pos)),
		member(KnightPos, Knights)
	;
		KnightPos is Pos + 10,
		valid_field(KnightPos),
		not(crosses_edge(KnightPos, Pos, KnightPos - Pos)),
		member(KnightPos, Knights)
	;
		KnightPos is Pos - 6,
		valid_field(KnightPos),
		not(crosses_edge(KnightPos, Pos, KnightPos - Pos)),
		member(KnightPos, Knights)
	;
		KnightPos is Pos - 10,
		valid_field(KnightPos),
		not(crosses_edge(KnightPos, Pos, KnightPos - Pos)),
		member(KnightPos, Knights)
	
	).

is_attacked_by_king(Pos, _Color, Kings) :-
	Kings = [KingPos],
	(
		KingPos is Pos + 1 ; % right
		KingPos is Pos - 1 ; % left
		KingPos is Pos + 8 ; % up
		KingPos is Pos - 8 ; % down
		KingPos is Pos + 9 ; % up-right
		KingPos is Pos + 7 ; % up-left
		KingPos is Pos - 7 ; % down-left
		KingPos is Pos - 9    % down-right
	).


multiple_steps_to_enemy(Field,Direction,Next,Color,Position):-
	invert(Color,FriendColor),
	one_step(Field,Direction,Next,FriendColor,Position),
	occupied(Next,Color,Position).
multiple_steps_to_enemy(Field,Direction,Next,Color,Position):-
	invert(Color,FriendColor),
	one_step(Field,Direction,FieldNew,FriendColor,Position),
	multiple_steps_to_enemy(FieldNew,Direction,Next,Color,Position).

inverse_long_move(From,Color,Type,Position, Direction, To) :-
	piece_direction(Type, Direction),
	multiple_steps_to_enemy(From, Direction, To, Color, Position).

is_attacked_on_line(Pos, Color, Position, Rooks, Bishops, Queens) :- 
    inverse_long_move(Pos, Color, queen, Position, Direction, To),
    (
        member(Direction, [7, -7, 9, -9]) ->
            (member(To, Bishops) ; member(To, Queens))
    ;
        member(Direction, [-1, 1, 8, -8]) ->
            (member(To, Rooks) ; member(To, Queens))
    ).


% main predicate to check if a position is under attack
is_under_attack(Pos, Color, Position) :-
	invert(Color, EnemyColor),
	get_half(Position, half_position(Pawns, Rooks, Knights, Bishops, Queens, Kings, _, _), EnemyColor),
	(   is_attacked_by_pawn(Pos, EnemyColor, Pawns)
	;   is_attacked_by_knight(Pos, EnemyColor, Knights)
	;  	is_attacked_by_king(Pos, EnemyColor, Kings)
	;   is_attacked_on_line(Pos, EnemyColor, Position, Rooks, Bishops, Queens)
	).

% check if king of given color is in check
in_check(Position, Color) :-
	find_king(Position, Color, KingPos),
	is_under_attack(KingPos, Color, Position).
