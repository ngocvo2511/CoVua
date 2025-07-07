% =================================
% Legal move
% =================================
% check if a move is legal (no getting checked, follow chess rule)
is_legal_move(From, To, Color, Position, BoardList, AttackData) :-
	% First check if the basic move is valid
	nth0(From, BoardList, [Type, _]),
	legal_move_for_piece(Type, From, To, Color, Position, BoardList, AttackData).
	% Then simulate the move and check if king is still safe
	% simulate_move(From, To, Color, Position, NewPosition, _MovedPiece, _CapturedPiece, _PromotedPiece, BoardList, AttackData, 0, _NewKey),
	% not(in_check(NewPosition, Color, BoardList, AttackData)).

% legal_move_for_piece: generate individual legal moves based on piece type
legal_move_for_piece(pawn, From, To, Color, Position, BoardList, AttackData) :-	
	pawn_move(Color, From, Position, To, BoardList, AttackData),
	AttackData = attack_data(
        InCheck, 
        _InDoubleCheck, 
        PinExist, 
        CheckRay, 
        PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        _OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
	(not(is_pinned(From, PinExist, PinRay)); is_moving_along_ray(Position, Color, From, To)),
	(InCheck = false; square_is_in_check_ray(To, InCheck, CheckRay)).

legal_move_for_piece(rook, From, To, Color, Position, BoardList, AttackData) :-
	long_move(rook, From, Color, Position, To, BoardList, AttackData),
	AttackData = attack_data(
        InCheck, 
        _InDoubleCheck, 
        PinExist, 
        CheckRay, 
        PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        _OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
	(not(is_pinned(From, PinExist, PinRay)); is_moving_along_ray(Position, Color, From, To)),
	(InCheck = false; square_is_in_check_ray(To, InCheck, CheckRay)).

legal_move_for_piece(knight, From, To, Color, Position, BoardList, AttackData) :-
	short_move(knight, From, Color, Position, To, BoardList, AttackData),
	AttackData = attack_data(
        InCheck, 
        _InDoubleCheck, 
        PinExist, 
        CheckRay, 
        PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        _OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
	not(is_pinned(From, PinExist, PinRay)),
	(InCheck = false; square_is_in_check_ray(To, InCheck, CheckRay)).

legal_move_for_piece(bishop, From, To, Color, Position, BoardList, AttackData) :-
	long_move(bishop, From, Color, Position, To, BoardList, AttackData),
	AttackData = attack_data(
        InCheck, 
        _InDoubleCheck, 
        PinExist, 
        CheckRay, 
        PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        _OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
	(not(is_pinned(From, PinExist, PinRay)); is_moving_along_ray(Position, Color, From, To)),
	(InCheck = false; square_is_in_check_ray(To, InCheck, CheckRay)).

legal_move_for_piece(queen, From, To, Color, Position, BoardList, AttackData) :-
	long_move(queen, From, Color, Position, To, BoardList, AttackData),
	AttackData = attack_data(
        InCheck, 
        _InDoubleCheck, 
        PinExist, 
        CheckRay, 
        PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        _OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
	(not(is_pinned(From, PinExist, PinRay)); is_moving_along_ray(Position, Color, From, To)),
	(InCheck = false; square_is_in_check_ray(To, InCheck, CheckRay)).

legal_move_for_piece(king, From, To, Color, Position, BoardList, AttackData) :-
	short_move(king, From, Color, Position, To, BoardList, AttackData),
	AttackData = attack_data(
        InCheck, 
        _InDoubleCheck, 
        _PinExist, 
        CheckRay, 
        _PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
	(not(square_is_in_check_ray(To, InCheck, CheckRay)) ; nth0(To, BoardList, [_, _])),
	not(square_is_attacked(To, OpponentAttackMap)).

% Add castling moves for king
legal_move_for_piece(king, From, To, Color, Position, BoardList, AttackData) :-
	castling_move_check(Color, Position, From, To, BoardList, AttackData).

generate_move(Move, Color, Position, NewPosition, BoardList, AttackData) :-
	Move = move(From, To, MovedPiece, CapturedPiece, PromotedPiece),
	nth0(From, BoardList, [Type, _]),
	legal_move_for_piece(Type, From, To, Color, Position, BoardList, AttackData),
	simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, BoardList, AttackData, 0, _NewKey),
	not(in_check(NewPosition, Color, BoardList, AttackData)).

% create a new position after making a move
simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, BoardList, AttackData, Key, NewKey) :-
	nth0(From, BoardList, [MovedPiece, _]),
	invert(Color, OpponentColor),
	(is_promotion_move(From, To, Color, Position, BoardList, AttackData), MovedPiece = pawn -> Promoting = true ; Promoting = false),
	(	nth0(To, BoardList, [CapturedPiece, OpponentColor]) ->
		capture_piece(Position, OpponentColor, To, TempPosition, BoardList, AttackData)
	;   TempPosition = Position
	),
	% Check if this is a castling move
	(   (MovedPiece = king, is_castling_move(Color, From, To, BoardList, AttackData)) ->
	    castle_piece(TempPosition, Color, From, To, NewPosition, BoardList, AttackData)
	;   % Check if this is an en passant move
	    (MovedPiece = pawn, is_enpassant_move(From, To, Color, TempPosition, BoardList, AttackData)) ->
	    % Handle en passant: capture the pawn and move our pawn
	    (   Color = white ->
	        CapturedPawnPos is To - 8  % Black pawn is one rank below
	    ;   CapturedPawnPos is To + 8  % White pawn is one rank above
	    ),
		CapturedPiece = pawn,
	    capture_piece(TempPosition, OpponentColor, CapturedPawnPos, Temp2Position, BoardList, AttackData),
	    move_piece(Temp2Position, Color, From, To, NewPosition, BoardList, AttackData)
	;   % Check if this is a pawn promotion
		Promoting = true,
		((PromotedPiece == none) -> throw(error(promotion_required, context(place_piece, 'Pawn promotion requires piece choice'))) ; true),
		promotion(PromotedPiece),
	    % Handle pawn promotion
	    move_piece(TempPosition, Color, From, To, Temp2Position, BoardList, AttackData),
	    promote_pawn(Temp2Position, Color, To, PromotedPiece, NewPosition, BoardList, AttackData)
	;   % Check if there's an opponent piece to capture
		Promoting = false,
		move_piece(TempPosition, Color, From, To, NewPosition, BoardList, AttackData)
	),
	(var(CapturedPiece) -> CapturedPiece = none ; true),
	(var(PromotedPiece) -> PromotedPiece = none ; true),
	% Update zobrist key based on the move
	update_zobrist_key_for_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, BoardList, AttackData, Key, NewKey).

% get_all_legal_moves: get all legal moves for a color
get_all_legal_moves(Position, Color, LegalMoves, BoardList, AttackData) :-
	get_all_pseudo_legal_moves(Position, Color, PseudoMoves, BoardList, AttackData),
	include(is_move_legal(Position, Color, BoardList, AttackData), PseudoMoves, LegalMoves).

% Helper predicate to check if a move is legal (doesn't leave king in check)
is_move_legal(Position, Color, BoardList, AttackData, move(From, To, MovedPiece, CapturedPiece, PromotedPiece)) :-
	simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, BoardList, AttackData, 0, _NewKey),
	not(in_check(NewPosition, Color, BoardList, AttackData)).
% faster version that does not check for king safety
get_all_pseudo_legal_moves(Position, Color, LegalMoves, BoardList, AttackData) :-
	invert(Color, OpponentColor),
	AttackData = attack_data(
        _InCheck, 
        InDoubleCheck, 
        _PinExist, 
        _CheckRay, 
        _PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        _OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
	(InDoubleCheck = true -> MovedPiece = king ; true),
	findall(move(From, To, MovedPiece, CapturedPiece, PromotedPiece), 
	        (	nth0(From, BoardList, [MovedPiece, Color]),
	         	legal_move_for_piece(MovedPiece, From, To, Color, Position, BoardList, AttackData),
	         	invert(Color, OpponentColor),
	         	% Determine captured piece
	        	(   nth0(To, BoardList, [CapturedPiece, OpponentColor]) ->
	            	true
	        	;   is_enpassant_move(From, To, Color, Position, BoardList, AttackData) ->
	            	CapturedPiece = pawn  % En passant captures the pawn
				;	CapturedPiece = none
	         	),
	         % Determine promotion piece
	        (   is_promotion_move(From, To, Color, Position, BoardList, AttackData) ->
	            (   PromotedPiece = queen
	            ;   PromotedPiece = knight
	            ;   PromotedPiece = rook
	            ;   PromotedPiece = bishop
	            )
	        ;   PromotedPiece = none
	        )
	        ),
	        LegalMoves).

get_all_noisy_pseudo_legal_moves(Position, Color, LegalMoves, BoardList, AttackData) :-
	invert(Color, OpponentColor),
	AttackData = attack_data(
        _InCheck, 
        InDoubleCheck, 
        _PinExist, 
        _CheckRay, 
        _PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        _OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
	(InDoubleCheck = true -> MovedPiece = king ; true),
	findall(move(From, To, MovedPiece, CapturedPiece, PromotedPiece), 
	        (	nth0(From, BoardList, [MovedPiece, Color]),
	         	legal_move_for_piece(MovedPiece, From, To, Color, Position, BoardList, AttackData),
	         	invert(Color, OpponentColor),
	         	% Determine captured piece
	        	(   nth0(To, BoardList, [CapturedPiece, OpponentColor]) ->
	            	true
	        	;   is_enpassant_move(From, To, Color, Position, BoardList, AttackData) ->
	            	CapturedPiece = pawn  % En passant captures the pawn
				;	false % No capture then not a noisy move
	         	),
	         % Determine promotion piece
	        (   is_promotion_move(From, To, Color, Position, BoardList, AttackData) ->
	            (   PromotedPiece = queen
	            ;   PromotedPiece = knight
	            )
	        ;   PromotedPiece = none
	        )
	        ),
	        LegalMoves).

% check if the given color is in checkmate
is_checkmate(Position, Color, BoardList, AttackData) :-
	in_check(Position, Color, BoardList, AttackData),
	get_all_legal_moves(Position, Color, [], BoardList, AttackData).  % No legal moves available

% is_stalemate: check if the given color is in stalemate
is_stalemate(Position, Color, BoardList, AttackData) :-
	not(in_check(Position, Color, BoardList, AttackData)),
	get_all_legal_moves(Position, Color, [], BoardList, AttackData).  % No legal moves but not in check

% =================================
% Piece movement on board
% =================================

% Direction vectors for different pieces (adjusted for 0-63 board)
% piece_direction: (piece, move value) - adjusted for 0-63 board
piece_direction(rook,8).    % up
piece_direction(rook,-8).   % down
piece_direction(rook,1).    % right
piece_direction(rook,-1).   % left
piece_direction(bishop,7).  % up-left diagonal
piece_direction(bishop,9).  % up-right diagonal
piece_direction(bishop,-7). % down-right diagonal
piece_direction(bishop,-9). % down-left diagonal
piece_direction(knight,15). % 2 up, 1 left
piece_direction(knight,17). % 2 up, 1 right
piece_direction(knight,6).  % 1 up, 2 left
piece_direction(knight,10). % 1 up, 2 right
piece_direction(knight,-6). % 1 down, 2 right
piece_direction(knight,-10).% 1 down, 2 left
piece_direction(knight,-15).% 2 down, 1 right
piece_direction(knight,-17).% 2 down, 1 left
piece_direction(queen,X):-
	piece_direction(rook,X).
piece_direction(queen,X):-
	piece_direction(bishop,X).
piece_direction(king,X):-
	piece_direction(queen,X).

% Check if move crosses board edge (for 0-63 board)
crosses_edge(From,To,Direction) :-
	FromCol is From mod 8,
	ToCol is To mod 8,
	(   (Direction = 1, FromCol = 7) ;  % moving right from rightmost column
	    (Direction = -1, FromCol = 0) ; % moving left from leftmost column
	    (Direction = 7, FromCol = 0) ;  % diagonal moves that cross edges
	    (Direction = 9, FromCol = 7) ;
	    (Direction = -7, FromCol = 7) ;
	    (Direction = -9, FromCol = 0) ;
	    (member(Direction,[6,10,-10,-6]), abs(FromCol - ToCol) > 2) ; % knight moves crossing edges
	    (member(Direction,[15,17,-15,-17]), abs(FromCol - ToCol) > 2)
	).

% one_step: from Field to Next through one step
one_step(Field,Direction,Next,Color,_Position,BoardList):-
	Next is Field + Direction,
	valid_field(Next),
	not(crosses_edge(Field,Next,Direction)),
	not(nth0(Next, BoardList, [_,Color])).

% multiple_steps: from Field to Next through one or multiple steps
multiple_steps(Field,Direction,Next,Color,Position,BoardList):-
	one_step(Field,Direction,Next,Color,Position,BoardList).
multiple_steps(Field,Direction,Next,Color,Position,BoardList):-
	one_step(Field,Direction,FieldNew,Color,Position,BoardList),
	invert(Color,Oppo),
	not(nth0(FieldNew, BoardList, [_, Oppo])),
	multiple_steps(FieldNew,Direction,Next,Color,Position,BoardList).

% Pawn movement rules =
pawn_move(white, From, _Position, To, BoardList, _AttackData):-
	To is From + 7,  % capture diagonal left
	valid_field(To),
	not(crosses_edge(From,To,7)),
	nth0(To, BoardList, [_, black]).
pawn_move(white, From, Position, To, _BoardList, _AttackData):-
	To is From + 7,  % enpassant left
	valid_field(To),
	not(crosses_edge(From,To,7)),
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), white),
	Check is From - 1,
	member(Check,EnpassantList).
	
pawn_move(white, From, _Position, To, BoardList, _AttackData):-
	To is From + 8,  % move forward
	valid_field(To),
	nth0(To, BoardList, empty).
	
pawn_move(white, From, _Position, To, BoardList, _AttackData):-
	To is From + 9,  % capture diagonal right
	valid_field(To),
	not(crosses_edge(From,To,9)),
	nth0(To, BoardList, [_, black]).
pawn_move(white, From, Position, To, _BoardList, _AttackData):-
	To is From + 9,  % enpassant right
	valid_field(To),
	not(crosses_edge(From,To,9)),
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), white),
	Check is From + 1,
	member(Check,EnpassantList).
	
pawn_move(white, From, _Position, To, BoardList, _AttackData):-
	To is From + 16, % double move from starting position
	valid_field(To),
	nth0(To, BoardList, empty),
	OneSquareForward is From + 8,
	nth0(OneSquareForward, BoardList, empty),
	between(8, 15, From). % starting row for white pawns

pawn_move(black, From, _Position, To, BoardList, _AttackData):-
	To is From - 7,  % capture diagonal right
	valid_field(To),
	not(crosses_edge(From,To,-7)),
	nth0(To, BoardList, [_, white]).
pawn_move(black, From, Position, To, _BoardList, _AttackData):-
	To is From - 7,  % enpassant right
	valid_field(To),
	not(crosses_edge(From,To,-7)),
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), black),
	Check is From + 1,
	member(Check,EnpassantList).
	
pawn_move(black, From, _Position, To, BoardList, _AttackData):-
	To is From - 8,  % move forward
	valid_field(To),
	nth0(To, BoardList, empty).

pawn_move(black, From, _Position, To, BoardList, _AttackData):-
	To is From - 9,  % capture diagonal left
	valid_field(To),
	not(crosses_edge(From,To,-9)),
	nth0(To, BoardList, [_, white]).
pawn_move(black, From, Position, To, _BoardList, _AttackData):-
	To is From - 9,  % enpassant left
	valid_field(To),
	not(crosses_edge(From,To,-9)),
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), black),
	Check is From - 1,
	member(Check,EnpassantList).
	
pawn_move(black, From, _Position, To, BoardList, _AttackData):-
	To is From - 16, % double move from starting position
	valid_field(To),
	nth0(To, BoardList, empty),
	OneSquareForward is From - 8,
	nth0(OneSquareForward, BoardList, empty),
	between(48, 55, From). % starting row for black pawns

% =================================
% Castling 
% =================================

castling_move_check(Color, Position, From, To, BoardList, AttackData) :-
	get_half(Position, half_position(_,_,_,_,_,_,Castle,_), Color),
	member(Side, Castle),
	castling_move(Color, Side, Position, From, To, BoardList, AttackData).

% Kingside castling (short castling)
castling_move(white, kingside, _Position, From, To, BoardList, AttackData) :-
	AttackData = attack_data(
        _InCheck, 
        _InDoubleCheck, 
        _PinExist, 
        _CheckRay, 
        _PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
	From = 4,  % White king starting position
	To = 6,    % King moves to g1 (position 6)
	nth0(5, BoardList, empty),
	nth0(6, BoardList, empty),
	% king and squares it passes through are not under attack
	not(square_is_attacked(4, OpponentAttackMap)),  % King not in check
	not(square_is_attacked(5, OpponentAttackMap)),  % f1 not under attack
	not(square_is_attacked(6, OpponentAttackMap)).

castling_move(black, kingside, _Position, From, To, BoardList, AttackData) :-
	AttackData = attack_data(
        _InCheck, 
        _InDoubleCheck, 
        _PinExist, 
        _CheckRay, 
        _PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
	From = 60,  % Black king starting position
	To = 62,    % King moves to g8 (position 62)
	nth0(61, BoardList, empty),
	nth0(62, BoardList, empty),
	% king and squares it passes through are not under attack
	not(square_is_attacked(60, OpponentAttackMap)),  % King not in check
	not(square_is_attacked(61, OpponentAttackMap)),  % f8 not under attack
	not(square_is_attacked(62, OpponentAttackMap)), !.  % g8 not under attack

% Queenside castling (long castling)
castling_move(white, queenside, _Position, From, To, BoardList, AttackData) :-
	AttackData = attack_data(
        _InCheck, 
        _InDoubleCheck, 
        _PinExist, 
        _CheckRay, 
        _PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
	From = 4,  % White king starting position
	To = 2,    % King moves to c1 (position 2)
	nth0(1, BoardList, empty),
	nth0(2, BoardList, empty),
	nth0(3, BoardList, empty),
	% Additional check: king and squares it passes through are not under attack
	not(square_is_attacked(4, OpponentAttackMap)),  % King not in check
	not(square_is_attacked(3, OpponentAttackMap)),  % d1 not under attack
	not(square_is_attacked(2, OpponentAttackMap)), !.  % c1 not under attack

castling_move(black, queenside, _Position, From, To, BoardList, AttackData) :-
	AttackData = attack_data(
        _InCheck, 
        _InDoubleCheck, 
        _PinExist, 
        _CheckRay, 
        _PinRay, 
        _OpponentKnightAttacks, 
        _OpponentAttackMapNoPawns,
        OpponentAttackMap, 
        _OpponentPawnAttackMap, 
        _OpponentSlidingAttackMap
    ),
	From = 60,  % Black king starting position
	To = 58,    % King moves to c8 (position 58)
	nth0(57, BoardList, empty),
	nth0(58, BoardList, empty),
	nth0(59, BoardList, empty),
	% Additional check: king and squares it passes through are not under attack
	not(square_is_attacked(60, OpponentAttackMap)),  % King not in check
	not(square_is_attacked(59, OpponentAttackMap)),  % d8 not under attack
	not(square_is_attacked(58, OpponentAttackMap)), !.  % c8 not under attack

% long_move: move for long distance (rook, bishop, queen)
long_move(Type, From, Color, Position, To, BoardList, _AttackData):-
	piece_direction(Type,Direction),
	multiple_steps(From,Direction,To,Color,Position,BoardList).

% short_move: move for one step (king, knight)
short_move(Type, From, Color, Position, To, BoardList, _AttackData):-	
	piece_direction(Type,Direction),
	one_step(From,Direction,To,Color,Position,BoardList).

% =================================
% Pawn promotion
% =================================

% check if position is on promotion rank
is_promotion_rank(Pos, white) :-
	between(56, 63, Pos).  % 8th rank for white
is_promotion_rank(Pos, black) :-
	between(0, 7, Pos).    % 1st rank for black

% check if a pawn move results in promotion
is_promotion_move(From, To, Color, _Position, BoardList, _AttackData) :-
	nth0(From, BoardList, [pawn, Color]),
	is_promotion_rank(To, Color).

% promote_pawn: remove pawn and add promoted piece
promote_pawn(Position, Color, PawnPos, PromotedPiece, NewPosition, BoardList, AttackData) :-
	% Remove the pawn
	get_half(Position, Half, Color),
	extract(Half, pawn, PawnList),
	remove(PawnPos, PawnList, NewPawnList),
	combine(Half, pawn, NewPawnList, TempHalf),
	
	% Add the promoted piece
	extract(TempHalf, PromotedPiece, PieceList),
	combine(TempHalf, PromotedPiece, [PawnPos|PieceList], NewHalf),
	
	% Update the position
	update_half(Position, NewHalf, Color, NewPosition, BoardList, AttackData).

promotion(queen).
promotion(knight).
promotion(rook).
promotion(bishop).

% =================================
% Pawn enpassant
% =================================
% En passant move - white pawn
is_enpassant_move(From, To, white, Position, _BoardList, _AttackData) :-
	between(32, 39, From),    % White pawn on 5th rank
	between(40, 47, To),      % Moving to 6th rank
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), white),
	member(OpponentPawnPos, EnpassantList),  % Get opponent pawn position
	abs(To - OpponentPawnPos) =:= 8.         % Target square is 8 squares away from opponent pawn

% En passant move - black pawn
is_enpassant_move(From, To, black, Position, _BoardList, _AttackData) :-
	between(24, 31, From),    % Black pawn on 4th rank
	between(16, 23, To),      % Moving to 3rd rank
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), black),
	member(OpponentPawnPos, EnpassantList),  % Get opponent pawn position
	abs(To - OpponentPawnPos) =:= 8.         % Target square is 8 squares away from opponent pawn

% =================================
% Special checking functions
% =================================

is_pinned(Square, PinExist, PinRay) :-
	PinExist = true,
	((PinRay >> Square) /\ 1) =:= 1.

is_moving_along_ray(Position, Color, From, To) :-
	get_half(Position, Half, Color),
	find_king(Half, Color, _KingPos),
	Diff is abs(To - From),
	Dir is abs(_Direction),
	Diff \= 0,
	Diff mod Dir =:= 0.

square_is_in_check_ray(Square, InCheck, CheckRay) :-
	InCheck = true,
	((CheckRay >> Square) /\ 1) =:= 1.

square_is_attacked(Square, OpponentAttackMap) :-
	((OpponentAttackMap >> Square) /\ 1) =:= 1.

% =================================
% Zobrist Key Updates
% =================================

% Update zobrist key based on the move made
update_zobrist_key_for_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, BoardList, AttackData, Key, NewKey) :-
    % Start with the current key
    TempKey1 = Key,
    
    % Get old en passant file for later removal
    calculate_en_passant_hash(Position, OldEnPassantHash),
    
    % Get old castling rights for later removal
    calculate_castling_hash(Position, OldCastlingHash),
    
    % 1. Handle captured piece first (before XOR-ing the moving piece)
    (   CapturedPiece \= none ->
        invert(Color, OpponentColor),
        % Handle special case for en passant
        (   is_enpassant_move(From, To, Color, Position, BoardList, AttackData) ->
            % En passant: captured pawn is not on the target square
            (   Color = white ->
                CapturedPawnPos is To - 8
            ;   CapturedPawnPos is To + 8
            ),
            zobrist_piece(pawn, OpponentColor, CapturedPawnPos, CapturedValue)
        ;   % Regular capture
            zobrist_piece(CapturedPiece, OpponentColor, To, CapturedValue)
        ),
        TempKey2 is TempKey1 xor CapturedValue
    ;   TempKey2 = TempKey1
    ),
    
    % 2. Handle castling rook movement (before moving the king)
    (   (MovedPiece = king, is_castling_move(Color, From, To, BoardList, AttackData)) ->
        update_zobrist_for_castling_rook(Color, From, To, TempKey2, TempKey3)
    ;   TempKey3 = TempKey2
    ),
    
    % 3. XOR piece from original square
    zobrist_piece(MovedPiece, Color, From, FromValue),
    TempKey4 is TempKey3 xor FromValue,
    
    % 4. XOR piece to new square (handle promotion)
    (   PromotedPiece \= none ->
        % Promotion: place promoted piece on target square
        zobrist_piece(PromotedPiece, Color, To, ToValue)
    ;   % Regular move: place same piece on target square
        zobrist_piece(MovedPiece, Color, To, ToValue)
    ),
    TempKey5 is TempKey4 xor ToValue,
    
    % 5. Remove old en passant file if it existed
    (   OldEnPassantHash \= 0 ->
        TempKey6 is TempKey5 xor OldEnPassantHash
    ;   TempKey6 = TempKey5
    ),
    
    % 6. Add new en passant file if pawn double move
    (   (MovedPiece = pawn, is_pawn_double_move(From, To, Color)) ->
        en_passant_square_to_file(From, File),
        zobrist_en_passant(File, NewEnPassantHash),
        TempKey7 is TempKey6 xor NewEnPassantHash
    ;   TempKey7 = TempKey6
    ),
    
    % 7. Update castling rights
    (   castling_rights_changed(From, To, Color, Position) ->
        % Remove old castling rights
        TempKey8 is TempKey7 xor OldCastlingHash,
        % Add new castling rights
        calculate_new_castling_rights_zobrist(From, To, Color, Position, NewCastlingHash),
        TempKey9 is TempKey8 xor NewCastlingHash
    ;   TempKey9 = TempKey7
    ),
    
    % 8. XOR side to move (change turn)
    zobrist_side_to_move(SideToMoveValue),
    NewKey is TempKey9 xor SideToMoveValue.

% Check if castling rights changed due to this move
castling_rights_changed(From, To, Color, Position) :-
    Position = position(WhiteHalf, BlackHalf),
    WhiteHalf = half_position(_, _, _, _, _, _, WhiteCastling, _),
    BlackHalf = half_position(_, _, _, _, _, _, BlackCastling, _),
    
    % Check if any castling rights would be lost
    (   % King moved
        (From = 4, Color = white, WhiteCastling \= []) ;
        (From = 60, Color = black, BlackCastling \= []) ;
        % Rook moved from or captured on corner square
        (From = 0, member(queenside, WhiteCastling)) ;
        (From = 7, member(kingside, WhiteCastling)) ;
        (From = 56, member(queenside, BlackCastling)) ;
        (From = 63, member(kingside, BlackCastling)) ;
        (To = 0, member(queenside, WhiteCastling)) ;
        (To = 7, member(kingside, WhiteCastling)) ;
        (To = 56, member(queenside, BlackCastling)) ;
        (To = 63, member(kingside, BlackCastling))
    ).

% Calculate new castling rights zobrist hash
calculate_new_castling_rights_zobrist(From, To, Color, Position, NewCastlingHash) :-
    Position = position(WhiteHalf, BlackHalf),
    WhiteHalf = half_position(_, _, _, _, _, _, WhiteCastling, _),
    BlackHalf = half_position(_, _, _, _, _, _, BlackCastling, _),
    
    % Calculate new castling rights
    update_castling_for_piece_move(From, To, Color, WhiteCastling, BlackCastling, NewWhiteCastling, NewBlackCastling),
    
    % Convert to zobrist hash
    castling_rights_to_number(NewWhiteCastling, NewBlackCastling, CastlingRights),
    zobrist_castling(CastlingRights, NewCastlingHash).

% Update zobrist key for castling rook movement
update_zobrist_for_castling_rook(Color, From, To, Key, NewKey) :-
    % Determine if kingside or queenside castling
    (   Color = white ->
        (   To = 6 ->  % Kingside castling
            RookFrom = 7, RookTo = 5
        ;   To = 2 ->  % Queenside castling
            RookFrom = 0, RookTo = 3
        )
    ;   Color = black ->
        (   To = 62 -> % Kingside castling
            RookFrom = 63, RookTo = 61
        ;   To = 58 -> % Queenside castling
            RookFrom = 56, RookTo = 59
        )
    ),
    
    % XOR rook from original square
    zobrist_piece(rook, Color, RookFrom, RookFromValue),
    TempKey is Key xor RookFromValue,
    
    % XOR rook to new square
    zobrist_piece(rook, Color, RookTo, RookToValue),
    NewKey is TempKey xor RookToValue.

% Update zobrist key for castling rights changes
update_zobrist_for_castling_rights(From, To, Color, Position, NewPosition, Key, NewKey) :-
    % Get old castling rights
    calculate_castling_hash(Position, OldCastlingHash),
    
    % Calculate new castling rights based on the move
    calculate_new_castling_rights(From, To, Color, Position, TempNewPosition),
    calculate_castling_hash(TempNewPosition, NewCastlingHash),
    
    % If castling rights changed, update key
    (   OldCastlingHash \= NewCastlingHash ->
        TempKey is Key xor OldCastlingHash,
        NewKey is TempKey xor NewCastlingHash
    ;   NewKey = Key
    ).

% Calculate new castling rights after a move
calculate_new_castling_rights(From, To, Color, Position, NewPosition) :-
    Position = position(WhiteHalf, BlackHalf),
    
    % Get current castling rights
    WhiteHalf = half_position(WP, WR, WN, WB, WQ, WK, WhiteCastling, WEP),
    BlackHalf = half_position(BP, BR, BN, BB, BQ, BK, BlackCastling, BEP),
    
    % Update castling rights based on piece movement
    update_castling_for_piece_move(From, To, Color, WhiteCastling, BlackCastling, NewWhiteCastling, NewBlackCastling),
    
    % Create new position with updated castling rights
    NewWhiteHalf = half_position(WP, WR, WN, WB, WQ, WK, NewWhiteCastling, WEP),
    NewBlackHalf = half_position(BP, BR, BN, BB, BQ, BK, NewBlackCastling, BEP),
    NewPosition = position(NewWhiteHalf, NewBlackHalf).

% Update castling rights when pieces move
update_castling_for_piece_move(From, To, Color, WhiteCastling, BlackCastling, NewWhiteCastling, NewBlackCastling) :-
    % King move removes all castling rights for that color
    (   (From = 4, Color = white) ->  % White king moved
        NewWhiteCastling = [],
        NewBlackCastling = BlackCastling
    ;   (From = 60, Color = black) ->  % Black king moved
        NewWhiteCastling = WhiteCastling,
        NewBlackCastling = []
    ;   % Rook moves or rook captured removes castling rights for that side
        update_castling_for_rook_move(From, To, WhiteCastling, BlackCastling, NewWhiteCastling, NewBlackCastling)
    ).

% Update castling rights for rook movement or capture
update_castling_for_rook_move(From, To, WhiteCastling, BlackCastling, NewWhiteCastling, NewBlackCastling) :-
    % Check if rook moved from or was captured on corner squares
    (   (From = 0 ; To = 0) ->  % a1 rook affected
        exclude(==(queenside), WhiteCastling, NewWhiteCastling),
        NewBlackCastling = BlackCastling
    ;   (From = 7 ; To = 7) ->  % h1 rook affected
        exclude(==(kingside), WhiteCastling, NewWhiteCastling),
        NewBlackCastling = BlackCastling
    ;   (From = 56 ; To = 56) ->  % a8 rook affected
        NewWhiteCastling = WhiteCastling,
        exclude(==(queenside), BlackCastling, NewBlackCastling)
    ;   (From = 63 ; To = 63) ->  % h8 rook affected
        NewWhiteCastling = WhiteCastling,
        exclude(==(kingside), BlackCastling, NewBlackCastling)
    ;   % No rook squares affected
        NewWhiteCastling = WhiteCastling,
        NewBlackCastling = BlackCastling
    ).

% Update zobrist key for en passant file changes
update_zobrist_for_en_passant(From, To, Color, Position, NewPosition, MovedPiece, Key, NewKey) :-
    % Get old en passant hash
    calculate_en_passant_hash(Position, OldEnPassantHash),
    
    % Calculate new en passant state
    calculate_new_en_passant_state(From, To, Color, MovedPiece, Position, TempNewPosition),
    calculate_en_passant_hash(TempNewPosition, NewEnPassantHash),
    
    % If en passant file changed, update key
    (   OldEnPassantHash \= NewEnPassantHash ->
        TempKey is Key xor OldEnPassantHash,
        NewKey is TempKey xor NewEnPassantHash
    ;   NewKey = Key
    ).

% Calculate new en passant state after a move
calculate_new_en_passant_state(From, To, Color, MovedPiece, Position, NewPosition) :-
    Position = position(WhiteHalf, BlackHalf),
    
    % Clear old en passant states and set new one if pawn double move
    (   (MovedPiece = pawn, is_pawn_double_move(From, To, Color)) ->
        % Pawn double move creates en passant opportunity
        (   Color = white ->
            EnPassantSquare is From + 8,  % Square behind the pawn
            NewWhiteHalf = half_position(WP, WR, WN, WB, WQ, WK, WCastle, [EnPassantSquare]),
            NewBlackHalf = half_position(BP, BR, BN, BB, BQ, BK, BCastle, [])
        ;   Color = black ->
            EnPassantSquare is From - 8,  % Square behind the pawn
            NewWhiteHalf = half_position(WP, WR, WN, WB, WQ, WK, WCastle, []),
            NewBlackHalf = half_position(BP, BR, BN, BB, BQ, BK, BCastle, [EnPassantSquare])
        ),
        % Get the castling rights from original position
        WhiteHalf = half_position(WP, WR, WN, WB, WQ, WK, WCastle, _),
        BlackHalf = half_position(BP, BR, BN, BB, BQ, BK, BCastle, _)
    ;   % No pawn double move, clear en passant
        WhiteHalf = half_position(WP, WR, WN, WB, WQ, WK, WCastle, _),
        BlackHalf = half_position(BP, BR, BN, BB, BQ, BK, BCastle, _),
        NewWhiteHalf = half_position(WP, WR, WN, WB, WQ, WK, WCastle, []),
        NewBlackHalf = half_position(BP, BR, BN, BB, BQ, BK, BCastle, [])
    ),
    NewPosition = position(NewWhiteHalf, NewBlackHalf).

% Check if a pawn move is a double move
is_pawn_double_move(From, To, white) :-
    between(8, 15, From),   % White pawn starting rank
    To is From + 16.        % Moved two squares forward

is_pawn_double_move(From, To, black) :-
    between(48, 55, From),  % Black pawn starting rank  
    To is From - 16.        % Moved two squares forward

