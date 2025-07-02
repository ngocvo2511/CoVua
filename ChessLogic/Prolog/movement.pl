% =================================
% Legal move
% =================================
% check if a move is legal (no getting checked, follow chess rule)
is_legal_move(From, To, Color, Position, BoardList) :-
	% First check if the basic move is valid
	nth0(From, BoardList, [Type, _]),
	legal_move_for_piece(Type, From, To, Color, Position, BoardList),
	% Then simulate the move and check if king is still safe
	simulate_move(From, To, Color, Position, NewPosition, _MovedPiece, _CapturedPiece, _PromotedPiece, BoardList),
	not(in_check(NewPosition, Color, BoardList)).

% legal_move_for_piece: generate individual legal moves based on piece type
legal_move_for_piece(pawn, From, To, Color, Position, BoardList) :-
	pawn_move(Color, From, Position, To, BoardList).

legal_move_for_piece(rook, From, To, Color, Position, BoardList) :-
	long_move(rook, From, Color, Position, To, BoardList).

legal_move_for_piece(knight, From, To, Color, Position, BoardList) :-
	short_move(knight, From, Color, Position, To, BoardList).

legal_move_for_piece(bishop, From, To, Color, Position, BoardList) :-
	long_move(bishop, From, Color, Position, To, BoardList).

legal_move_for_piece(queen, From, To, Color, Position, BoardList) :-
	long_move(queen, From, Color, Position, To, BoardList).

legal_move_for_piece(king, From, To, Color, Position, BoardList) :-
	short_move(king, From, Color, Position, To, BoardList).

% Add castling moves for king
legal_move_for_piece(king, From, To, Color, Position, BoardList) :-
	castling_move_check(Color, Position, From, To, BoardList).

generate_move(Move, Color, Position, NewPosition, BoardList) :-
	Move = move(From, To, MovedPiece, CapturedPiece, PromotedPiece),
	nth0(From, BoardList, [Type, _]),
	legal_move_for_piece(Type, From, To, Color, Position, BoardList),
	simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, BoardList),
	not(in_check(NewPosition, Color, BoardList)).

% create a new position after making a move
simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, BoardList) :-
	nth0(From, BoardList, [MovedPiece, _]),
	invert(Color, OpponentColor),
	(is_promotion_move(From, To, Color, Position, BoardList), MovedPiece = pawn -> Promoting = true ; Promoting = false),
	(	nth0(To, BoardList, [CapturedPiece, OpponentColor]) ->
		capture_piece(Position, OpponentColor, To, TempPosition, BoardList)
	;   TempPosition = Position
	),
	% Check if this is a castling move
	(   (MovedPiece = king, is_castling_move(Color, From, To, BoardList)) ->
	    castle_piece(TempPosition, Color, From, To, NewPosition, BoardList)
	;   % Check if this is an en passant move
	    (MovedPiece = pawn, is_enpassant_move(From, To, Color, TempPosition, BoardList)) ->
	    % Handle en passant: capture the pawn and move our pawn
	    (   Color = white ->
	        CapturedPawnPos is To - 8  % Black pawn is one rank below
	    ;   CapturedPawnPos is To + 8  % White pawn is one rank above
	    ),
		CapturedPiece = pawn,
	    capture_piece(TempPosition, OpponentColor, CapturedPawnPos, Temp2Position, BoardList),
	    move_piece(Temp2Position, Color, From, To, NewPosition, BoardList)
	;   % Check if this is a pawn promotion
		Promoting = true,
		((PromotedPiece == null) -> throw(error(promotion_required, context(place_piece, 'Pawn promotion requires piece choice'))) ; true),
		promotion(PromotedPiece),
	    % Handle pawn promotion
	    move_piece(TempPosition, Color, From, To, Temp2Position, BoardList),
	    promote_pawn(Temp2Position, Color, To, PromotedPiece, NewPosition, BoardList)
	;   % Check if there's an opponent piece to capture
		Promoting = false,
		move_piece(TempPosition, Color, From, To, NewPosition, BoardList)
	),
	(var(CapturedPiece) -> CapturedPiece = none ; true),
	(var(PromotedPiece) -> PromotedPiece = none ; true).

% get_all_legal_moves: get all legal moves for a color
get_all_legal_moves(Position, Color, LegalMoves, BoardList) :-
	get_all_pseudo_legal_moves(Position, Color, PseudoMoves, BoardList),
	include(is_move_legal(Position, Color, BoardList), PseudoMoves, LegalMoves).

% Helper predicate to check if a move is legal (doesn't leave king in check)
is_move_legal(Position, Color, BoardList, move(From, To, MovedPiece, CapturedPiece, PromotedPiece)) :-
	simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, BoardList),
	not(in_check(NewPosition, Color, BoardList)).
% faster version that does not check for king safety
get_all_pseudo_legal_moves(Position, Color, LegalMoves, BoardList) :-
	invert(Color, OpponentColor),
	findall(move(From, To, MovedPiece, CapturedPiece, PromotedPiece), 
	        (	nth0(From, BoardList, [MovedPiece, Color]),
	         	legal_move_for_piece(MovedPiece, From, To, Color, Position, BoardList),
	         	invert(Color, OpponentColor),
	         	% Determine captured piece
	        	(   nth0(To, BoardList, [CapturedPiece, OpponentColor]) ->
	            	true
	        	;   is_enpassant_move(From, To, Color, Position, BoardList) ->
	            	CapturedPiece = pawn  % En passant captures the pawn
				;	CapturedPiece = none
	         	),
	         % Determine promotion piece
	        (   is_promotion_move(From, To, Color, Position, BoardList) ->
	            (   PromotedPiece = queen
	            ;   PromotedPiece = knight
	            ;   PromotedPiece = rook
	            ;   PromotedPiece = bishop
	            )
	        ;   PromotedPiece = none
	        )
	        ),
	        LegalMoves).

% check if the given color is in checkmate
is_checkmate(Position, Color, BoardList) :-
	in_check(Position, Color, BoardList),
	get_all_legal_moves(Position, Color, [], BoardList).  % No legal moves available

% is_stalemate: check if the given color is in stalemate
is_stalemate(Position, Color, BoardList) :-
	not(in_check(Position, Color, BoardList)),
	get_all_legal_moves(Position, Color, [], BoardList).  % No legal moves but not in check

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
pawn_move(white, From, _Position, To, BoardList):-
	To is From + 7,  % capture diagonal left
	valid_field(To),
	not(crosses_edge(From,To,7)),
	nth0(To, BoardList, [_, black]).
pawn_move(white, From, Position, To, _BoardList):-
	To is From + 7,  % enpassant left
	valid_field(To),
	not(crosses_edge(From,To,7)),
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), white),
	Check is From - 1,
	member(Check,EnpassantList).
	
pawn_move(white, From, _Position, To, BoardList):-
	To is From + 8,  % move forward
	valid_field(To),
	nth0(To, BoardList, empty).
	
pawn_move(white, From, _Position, To, BoardList):-
	To is From + 9,  % capture diagonal right
	valid_field(To),
	not(crosses_edge(From,To,9)),
	nth0(To, BoardList, [_, black]).
pawn_move(white, From, Position, To, _BoardList):-
	To is From + 9,  % enpassant right
	valid_field(To),
	not(crosses_edge(From,To,9)),
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), white),
	Check is From + 1,
	member(Check,EnpassantList).
	
pawn_move(white, From, _Position, To, BoardList):-
	To is From + 16, % double move from starting position
	valid_field(To),
	nth0(To, BoardList, empty),
	OneSquareForward is From + 8,
	nth0(OneSquareForward, BoardList, empty),
	between(8, 15, From). % starting row for white pawns

pawn_move(black, From, _Position, To, BoardList):-
	To is From - 7,  % capture diagonal right
	valid_field(To),
	not(crosses_edge(From,To,-7)),
	nth0(To, BoardList, [_, white]).
pawn_move(black, From, Position, To, _BoardList):-
	To is From - 7,  % enpassant right
	valid_field(To),
	not(crosses_edge(From,To,-7)),
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), black),
	Check is From + 1,
	member(Check,EnpassantList).
	
pawn_move(black, From, _Position, To, BoardList):-
	To is From - 8,  % move forward
	valid_field(To),
	nth0(To, BoardList, empty).

pawn_move(black, From, _Position, To, BoardList):-
	To is From - 9,  % capture diagonal left
	valid_field(To),
	not(crosses_edge(From,To,-9)),
	nth0(To, BoardList, [_, white]).
pawn_move(black, From, Position, To, _BoardList):-
	To is From - 9,  % enpassant left
	valid_field(To),
	not(crosses_edge(From,To,-9)),
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), black),
	Check is From - 1,
	member(Check,EnpassantList).
	
pawn_move(black, From, _Position, To, BoardList):-
	To is From - 16, % double move from starting position
	valid_field(To),
	not(nth0(To, BoardList, empty)),
	OneSquareForward is From - 8,
	not(nth0(OneSquareForward, BoardList, empty)),
	between(48, 55, From). % starting row for black pawns

% =================================
% Castling 
% =================================

castling_move_check(Color, Position, From, To, BoardList) :-
	get_half(Position, half_position(_,_,_,_,_,_,Castle,_), Color),
	member(Side, Castle),
	castling_move(Color, Side, Position, From, To, BoardList).

% Kingside castling (short castling)
castling_move(white, kingside, Position, From, To, BoardList) :-
	From = 4,  % White king starting position
	To = 6,    % King moves to g1 (position 6)
	nth0(5, BoardList, empty),
	nth0(6, BoardList, empty),
	% king and squares it passes through are not under attack
	not(is_under_attack(4, white, Position, BoardList)),  % King not in check
	not(is_under_attack(5, white, Position, BoardList)),  % f1 not under attack
	not(is_under_attack(6, white, Position, BoardList)), !.  % g1 not under attack

castling_move(black, kingside, Position, From, To, BoardList) :-
	From = 60,  % Black king starting position
	To = 62,    % King moves to g8 (position 62)
	nth0(61, BoardList, empty),
	nth0(62, BoardList, empty),
	% king and squares it passes through are not under attack
	not(is_under_attack(60, black, Position, BoardList)),  % King not in check
	not(is_under_attack(61, black, Position, BoardList)),  % f8 not under attack
	not(is_under_attack(62, black, Position, BoardList)), !.  % g8 not under attack

% Queenside castling (long castling)
castling_move(white, queenside, Position, From, To, BoardList) :-
	From = 4,  % White king starting position
	To = 2,    % King moves to c1 (position 2)
	nth0(1, BoardList, empty),
	nth0(2, BoardList, empty),
	nth0(3, BoardList, empty),
	% Additional check: king and squares it passes through are not under attack
	not(is_under_attack(4, white, Position, BoardList)),  % King not in check
	not(is_under_attack(3, white, Position, BoardList)),  % d1 not under attack
	not(is_under_attack(2, white, Position, BoardList)), !.  % c1 not under attack

castling_move(black, queenside, Position, From, To, BoardList) :-
	From = 60,  % Black king starting position
	To = 58,    % King moves to c8 (position 58)
	nth0(57, BoardList, empty),
	nth0(58, BoardList, empty),
	nth0(59, BoardList, empty),
	% Additional check: king and squares it passes through are not under attack
	not(is_under_attack(60, black, Position, BoardList)),  % King not in check
	not(is_under_attack(59, black, Position, BoardList)),  % d8 not under attack
	not(is_under_attack(58, black, Position, BoardList)), !.  % c8 not under attack

% long_move: move for long distance (rook, bishop, queen)
long_move(Type, From, Color, Position, To, BoardList):-
	piece_direction(Type,Direction),
	multiple_steps(From,Direction,To,Color,Position,BoardList).

% short_move: move for one step (king, knight)
short_move(Type, From, Color, Position, To, BoardList):-
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
is_promotion_move(From, To, Color, _Position, BoardList) :-
	nth0(From, BoardList, [pawn, Color]),
	is_promotion_rank(To, Color).

% promote_pawn: remove pawn and add promoted piece
promote_pawn(Position, Color, PawnPos, PromotedPiece, NewPosition, BoardList) :-
	% Remove the pawn
	get_half(Position, Half, Color),
	extract(Half, pawn, PawnList),
	remove(PawnPos, PawnList, NewPawnList),
	combine(Half, pawn, NewPawnList, TempHalf),
	
	% Add the promoted piece
	extract(TempHalf, PromotedPiece, PieceList),
	combine(TempHalf, PromotedPiece, [PawnPos|PieceList], NewHalf),
	
	% Update the position
	update_half(Position, NewHalf, Color, NewPosition, BoardList).

promotion(queen).
promotion(knight).
promotion(rook).
promotion(bishop).

% =================================
% Pawn enpassant
% =================================
% En passant move - white pawn
is_enpassant_move(From, To, white, Position, _BoardList) :-
	between(32, 39, From),    % White pawn on 5th rank
	between(40, 47, To),      % Moving to 6th rank
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), white),
	member(OpponentPawnPos, EnpassantList),  % Get opponent pawn position
	abs(To - OpponentPawnPos) =:= 8.         % Target square is 8 squares away from opponent pawn

% En passant move - black pawn
is_enpassant_move(From, To, black, Position, _BoardList) :-
	between(24, 31, From),    % Black pawn on 4th rank
	between(16, 23, To),      % Moving to 3rd rank
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), black),
	member(OpponentPawnPos, EnpassantList),  % Get opponent pawn position
	abs(To - OpponentPawnPos) =:= 8.         % Target square is 8 squares away from opponent pawn