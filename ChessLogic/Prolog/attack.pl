% find_king: find the position of king for given color
find_king(Position, Color, KingPos) :-
	get_half(Position, half_position(_,_,_,_,_,[KingPos],_,_), Color).

% is_attacked_by_pawn: check if position is attacked by enemy pawn
is_attacked_by_pawn(Pos, Color, Position) :-
	invert(Color, EnemyColor),
	get_half(Position, EnemyHalf, EnemyColor),
	extract(EnemyHalf, pawn, EnemyPawns),
	member(PawnPos, EnemyPawns),
	pawn_attacks(PawnPos, EnemyColor, Pos).

% pawn_attacks: define pawn attack patterns
pawn_attacks(PawnPos, white, AttackPos) :-
	(   AttackPos is PawnPos + 7  % diagonal left attack
	;   AttackPos is PawnPos + 9  % diagonal right attack
	),
	not(invalid_field(AttackPos)),
	not(crosses_edge(PawnPos, AttackPos, AttackPos - PawnPos)).

pawn_attacks(PawnPos, black, AttackPos) :-
	(   AttackPos is PawnPos - 7  % diagonal right attack
	;   AttackPos is PawnPos - 9  % diagonal left attack
	),
	not(invalid_field(AttackPos)),
	not(crosses_edge(PawnPos, AttackPos, AttackPos - PawnPos)).

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

% is_under_attack: main predicate to check if a position is under attack
is_under_attack(Pos, Color, Position) :-
	(   is_attacked_by_pawn(Pos, Color, Position)
	;   is_attacked_by_piece(Pos, Color, Position, knight)
	;   is_attacked_by_piece(Pos, Color, Position, bishop)
	;   is_attacked_by_piece(Pos, Color, Position, rook)
	;   is_attacked_by_piece(Pos, Color, Position, queen)
	;   is_attacked_by_piece(Pos, Color, Position, king)
	).

% in_check: check if king of given color is in check
in_check(Position, Color) :-
	find_king(Position, Color, KingPos),
	is_under_attack(KingPos, Color, Position).
