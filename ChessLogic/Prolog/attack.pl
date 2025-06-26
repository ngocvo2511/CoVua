% find_king: find the position of king for given color
find_king(Position, Color, KingPos) :-
	get_half(Position, half_position(_,_,_,_,_,[KingPos],_,_), Color).

% is_attacked_by_pawn: check if position is attacked by enemy pawn
is_attacked_by_pawn(Pos, Color, Pawns) :-
	(
		Color = white ->
		(
			PawnPos is Pos + 7,  % diagonal left attack
			valid_field(PawnPos),
			not(crosses_edge(PawnPos, Pos, PawnPos - Pos)),
			member(PawnPos, Pawns)
		;   
			PawnPos is Pos + 9,  % diagonal right attack
			valid_field(PawnPos),
			not(crosses_edge(PawnPos, Pos, PawnPos - Pos)),
			member(PawnPos, Pawns)
		)
		;
		Color = black ->
		(
			PawnPos is Pos - 7,  % diagonal right attack
			valid_field(PawnPos),
			not(crosses_edge(PawnPos, Pos, PawnPos - Pos)),
			member(PawnPos, Pawns)
		;
			PawnPos is Pos - 9,  % diagonal left attack
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

is_attacked_on_line(Pos, Color, Position, Rooks, Bishops, Queens) :- true.

% is_attacked_by_piece: check if position is attacked by specific piece type
is_attacked_by_piece(Pos, Color, Position, PieceType) :-
	invert(Color, EnemyColor),
	get_half(Position, EnemyHalf, EnemyColor),
	extract(EnemyHalf, PieceType, Pieces),
	member(PiecePos, Pieces),
	can_attack(PiecePos, PieceType, EnemyColor, Position, Pos).

% can_attack: check if a piece can attack a position
can_attack(From, knight, Color, Position, To) :-
	short_move(From, Color, knight, Position, To).

can_attack(From, king, Color, Position, To) :-
	short_move(From, Color, king, Position, To).

can_attack(From, PieceType, Color, Position, To) :-
	member(PieceType, [rook, bishop, queen]),
	long_move(From, Color, PieceType, Position, To).

% main predicate to check if a position is under attack
is_under_attack(Pos, Color, Position) :-
	invert(Color, EnemyColor),
	get_half(Position, half_position(Pawns, Rooks, Knights, Bishops, Queens, Kings, _, _), EnemyColor),
	(   is_attacked_by_pawn(Pos, Color, Pawns)
	;   is_attacked_by_knight(Pos, Color, Knights)
	;  	is_attacked_by_king(Pos, Color, Kings)
	;   is_attacked_on_line(Pos, Color, Position, Rooks, Bishops, Queens)
	).

% check if king of given color is in check
in_check(Position, Color) :-
	find_king(Position, Color, KingPos),
	is_under_attack(KingPos, Color, Position).
