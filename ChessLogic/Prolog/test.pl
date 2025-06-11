% predicate to check current game status
check_game_status :-
	board(Position, Color),
	(   in_check(Color, Position) ->
	    (   is_checkmate(Color, Position) ->
	        write('CHECKMATE'), nl,
	        reset
	    ;   write('CHECK'), nl
	    )
	;   is_stalemate(Color, Position) ->
	    write('STALEMATE'), nl,
	    reset
	).


test_check :-
	only_king_and_rooks(Position),
	set_position(Position,white),
	write('Testing check detection:'), nl,
	board(Pos, _),
	write('White king in check: '),
	(in_check(white, Pos) -> write('Yes') ; write('No')), nl,
	write('Black king in check: '),
	(in_check(black, Pos) -> write('Yes') ; write('No')), nl.
	
test_pawn_promotion :-
	only_king_and_pawns(Position),
	set_position(Position,white).


only_king_and_rooks(position(H1, H2, 0)) :-
    H1 = half_position([], [0, 7], [], [], [], [4], notmoved),
    H2 = half_position([], [56, 63], [], [], [], [60], notmoved).
	
only_king_and_pawns(position(H1, H2, 0)) :-
    H1 = half_position([51], [], [], [], [], [5], notmoved),
    H2 = half_position([11], [], [], [], [], [61], notmoved).