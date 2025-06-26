test_check :-
	only_king_and_rooks(Position),
	set_position(Position,white),
	write('Testing check detection:'), nl,
	board(Pos, _, _),
	write('White king in check: '),
	(in_check(Pos, white) -> write('Yes') ; write('No')), nl,
	write('Black king in check: '),
	(in_check(Pos, black) -> write('Yes') ; write('No')), nl.
	
test_pawn_promotion :-
	only_king_and_pawns(Position),
	set_position(Position,white).
	
test_enpassant :-
	enpassant_position(Position),
	set_position(Position,white).

test_threefold :-
	threefold_position(Position),
	set_position(Position,white).

only_king_and_rooks(position(H1, H2)) :-
    H1 = half_position([],[],[],[],[],[4],[queenside,kingside],[]),
    H2 = half_position([],[8, 23],[],[],[],[60],[queenside,kingside],[]).
	
only_king_and_pawns(position(H1, H2)) :-
    H1 = half_position([48],[],[],[],[],[4],[queenside,kingside],[]),
    H2 = half_position([8],[],[],[],[],[60],[queenside,kingside],[]).

enpassant_position(position(H1, H2)) :-
    H1 = half_position([35],[],[],[],[],[4],[],[]),
    H2 = half_position([52],[],[],[],[],[60],[],[]).
	
threefold_position(position(H1, H2)) :-
	H1 = half_position([],[1],[],[],[],[4],[],[]),
    H2 = half_position([],[],[],[],[],[56],[],[]).

test_time :-
	initial_pos(Position),
	get_all_legal_moves(Position, white, _MoveList).

test_incheck :-
	board(Pos, Color, _Counter),
	(in_check(Pos, white) -> write('Yes') ; write('No')), nl,
	(in_check(Pos, black) -> write('Yes') ; write('No')), nl.