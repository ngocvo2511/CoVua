% =================================
% Legal move
% =================================

% if a piece is at that position
get_piece_position(half_position(Pawns,_,_,_,_,_,_,_), Pos, pawn) :- member(Pos, Pawns).
get_piece_position(half_position(_,Rooks,_,_,_,_,_,_), Pos, rook) :- member(Pos, Rooks).
get_piece_position(half_position(_,_,Knights,_,_,_,_,_), Pos, knight) :- member(Pos, Knights).
get_piece_position(half_position(_,_,_,Bishops,_,_,_,_), Pos, bishop) :- member(Pos, Bishops).
get_piece_position(half_position(_,_,_,_,Queens,_,_,_), Pos, queen) :- member(Pos, Queens).
get_piece_position(half_position(_,_,_,_,_,Kings,_,_), Pos, king) :- member(Pos, Kings).
get_piece_position(half_position(_,_,_,_,_,_,Castles,_), Pos, king) :- member(Pos, Castles).
get_piece_position(half_position(_,_,_,_,_,_,_,Enpassants), Pos, king) :- member(Pos, Enpassants).

% check if a move is legal (no getting checked, follow chess rule)
is_legal_move(From, To, Color, Position, PromotionPiece) :-
	% First check if the basic move is valid
	find_piece_type(From, Type, Position, Color),
	legal_move_for_piece(From, To, Type, Color, Position),
	% Then simulate the move and check if king is still safe
	simulate_move(From, To, Color, Position, NewPosition, PromotionPiece),
	not(in_check(NewPosition, Color)).

% legal_move_for_piece: generate individual legal moves based on piece type
legal_move_for_piece(From, To, pawn, Color, Position) :-
	pawn_move(From, Color, Position, To).

legal_move_for_piece(From, To, rook, Color, Position) :-
	long_move(From, Color, rook, Position, To).

legal_move_for_piece(From, To, knight, Color, Position) :-
	short_move(From, Color, knight, Position, To).

legal_move_for_piece(From, To, bishop, Color, Position) :-
	long_move(From, Color, bishop, Position, To).

legal_move_for_piece(From, To, queen, Color, Position) :-
	long_move(From, Color, queen, Position, To).

legal_move_for_piece(From, To, king, Color, Position) :-
	short_move(From, Color, king, Position, To).

% Add castling moves for king
legal_move_for_piece(From, To, king, Color, Position) :-
	castling_move(From, Color, Position, To).

% create a new position after making a move
simulate_move(From, To, Color, Position, NewPosition, PromotionPiece) :-
	find_piece_type(From, Type, Position, Color),
	invert(Color, OpponentColor),
	% Check if this is a castling move
	(   (Type = king, is_castling_move(Color, From, To)) ->
	    % Handle castling
	    castle_move(Position, Color, From, To, NewPosition)
	;   % Check if this is an en passant move
	    (Type = pawn, is_enpassant_move(From, To, Color, Position)) ->
	    % Handle en passant: capture the pawn and move our pawn
	    (   Color = white ->
	        CapturedPawnPos is To - 8  % Black pawn is one rank below
	    ;   CapturedPawnPos is To + 8  % White pawn is one rank above
	    ),
	    capture_piece(Position, OpponentColor, CapturedPawnPos, TempPosition),
	    move_piece(TempPosition, Color, From, To, NewPosition)
	;   % Check if this is a pawn promotion
	    (Type = pawn, is_promotion_move(From, To, Color, Position), 
			(
				var(PromotionPiece) -> bot_promotion(PromotionPiece)
			;	PromotionPiece = null -> throw(error(promotion_required, context(place_piece, 'Pawn promotion requires piece choice')))
			;	true
			)) ->
	    % Handle pawn promotion
	    (   occupied(To, OpponentColor, Position) ->
	        % Promotion with capture
	        capture_piece(Position, OpponentColor, To, TempPosition),
	        move_piece(TempPosition, Color, From, To, TempPosition2),
	        promote_pawn(TempPosition2, Color, To, PromotionPiece, NewPosition)
	    ;   % Promotion without capture
	        move_piece(Position, Color, From, To, TempPosition),
	        promote_pawn(TempPosition, Color, To, PromotionPiece, NewPosition)
	    )
	;   % Check if there's an opponent piece to capture
	    (   occupied(To, OpponentColor, Position) ->
	        % Capture move: remove opponent piece first, then move our piece
	        capture_piece(Position, OpponentColor, To, TempPosition),
	        move_piece(TempPosition, Color, From, To, NewPosition)
	    ;   % Normal move: just move our piece
	        move_piece(Position, Color, From, To, NewPosition)
	    )
	), 				write(To), nl
.

% get_all_legal_moves: get all legal moves for a color
get_all_legal_moves(Position, Color, LegalMoves) :-
	findall(move(From, To, PromotionPiece), 
	        (get_half(Position, Half, Color),
	         get_piece_position(Half, From, _Type),
	         is_legal_move(From, To, Color, Position, PromotionPiece)),
	        LegalMoves).

% check if the given color is in checkmate
is_checkmate(Position, Color) :-
	in_check(Position, Color),
	get_all_legal_moves(Position, Color, []).  % No legal moves available

% is_stalemate: check if the given color is in stalemate
is_stalemate(Position, Color) :-
	not(in_check(Position, Color)),
	get_all_legal_moves(Position, Color, []).  % No legal moves but not in check

% =================================
% Piece movement on board
% =================================

% Direction vectors for different pieces (adjusted for 0-63 board)
% poss_move: (piece, move value) - adjusted for 0-63 board
poss_move(rook,8).    % up
poss_move(rook,-8).   % down
poss_move(rook,1).    % right
poss_move(rook,-1).   % left
poss_move(bishop,7).  % up-left diagonal
poss_move(bishop,9).  % up-right diagonal
poss_move(bishop,-7). % down-right diagonal
poss_move(bishop,-9). % down-left diagonal
poss_move(knight,15). % 2 up, 1 left
poss_move(knight,17). % 2 up, 1 right
poss_move(knight,6).  % 1 up, 2 left
poss_move(knight,10). % 1 up, 2 right
poss_move(knight,-6). % 1 down, 2 right
poss_move(knight,-10).% 1 down, 2 left
poss_move(knight,-15).% 2 down, 1 right
poss_move(knight,-17).% 2 down, 1 left
poss_move(queen,X):-
	poss_move(rook,X).
poss_move(queen,X):-
	poss_move(bishop,X).
poss_move(king,X):-
	poss_move(queen,X).

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
one_step(Field,Direction,Next,Color,Position):-	
	Next is Field + Direction,
	valid_field(Next),
	not(crosses_edge(Field,Next,Direction)),
	not(occupied(Next,Color,Position)).

% multiple_steps: from Field to Next through one or multiple steps
multiple_steps(Field,Direction,Next,Color,Position):-
	one_step(Field,Direction,Next,Color,Position).
multiple_steps(Field,Direction,Next,Color,Position):-
	one_step(Field,Direction,FieldNew,Color,Position),
	invert(Color,Oppo),
	not(occupied(FieldNew,Oppo,Position)),
	multiple_steps(FieldNew,Direction,Next,Color,Position).

% Pawn movement rules =
pawn_move(From,white,Position,To):-
	To is From + 7,  % capture diagonal left
	valid_field(To),
	not(crosses_edge(From,To,7)),
	occupied(To,black,Position).
pawn_move(From,white,Position,To):-
	To is From + 7,  % enpassant left
	valid_field(To),
	not(crosses_edge(From,To,7)),
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), white),
	Check is From - 1,
	member(Check,EnpassantList).
	
pawn_move(From,white,Position,To):-
	To is From + 8,  % move forward
	valid_field(To),
	unoccupied(To,Position).
	
pawn_move(From,white,Position,To):-
	To is From + 9,  % capture diagonal right
	valid_field(To),
	not(crosses_edge(From,To,9)),
	occupied(To,black,Position).
pawn_move(From,white,Position,To):-
	To is From + 9,  % enpassant right
	valid_field(To),
	not(crosses_edge(From,To,9)),
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), white),
	Check is From + 1,
	member(Check,EnpassantList).
	
pawn_move(From,white,Position,To):-
	To is From + 16, % double move from starting position
	valid_field(To),
	unoccupied(To,Position),
	OneSquareForward is From + 8,
	unoccupied(OneSquareForward, Position),
	between(8, 15, From). % starting row for white pawns

pawn_move(From,black,Position,To):-
	To is From - 7,  % capture diagonal right
	valid_field(To),
	not(crosses_edge(From,To,-7)),
	occupied(To,white,Position).
pawn_move(From,black,Position,To):-
	To is From - 7,  % enpassant right
	valid_field(To),
	not(crosses_edge(From,To,-7)),
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), white),
	Check is From + 1,
	member(Check,EnpassantList).
	
pawn_move(From,black,Position,To):-
	To is From - 8,  % move forward
	valid_field(To),
	unoccupied(To,Position).
	
pawn_move(From,black,Position,To):-
	To is From - 9,  % capture diagonal left
	valid_field(To),
	not(crosses_edge(From,To,-9)),
	occupied(To,white,Position).
pawn_move(From,black,Position,To):-
	To is From - 9,  % enpassant left
	valid_field(To),
	not(crosses_edge(From,To,-9)),
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), white),
	Check is From - 1,
	member(Check,EnpassantList).
	
pawn_move(From,black,Position,To):-
	To is From - 16, % double move from starting position
	valid_field(To),
	unoccupied(To,Position),
	OneSquareForward is From - 8,
	unoccupied(OneSquareForward,Position),
	between(48, 55, From). % starting row for black pawns

% =================================
% Castling 
% =================================

% Kingside castling (short castling)
castling_move(From, white, Position, To) :-
	From = 4,  % White king starting position
	To = 6,    % King moves to g1 (position 6)
	get_half(Position, half_position(_,_,_,_,_,_,Castle,_), white),
	member(kingside,Castle),
	unoccupied(5, Position),  % f1 is empty
	unoccupied(6, Position),  % g1 is empty
	% king and squares it passes through are not under attack
	not(is_under_attack(4, white, Position)),  % King not in check
	not(is_under_attack(5, white, Position)),  % f1 not under attack
	not(is_under_attack(6, white, Position)).  % g1 not under attack

castling_move(From, black, Position, To) :-
	From = 60,  % Black king starting position
	To = 62,    % King moves to g8 (position 62)
	get_half(Position, half_position(_,_,_,_,_,_,Castle,_), black),
	member(kingside,Castle),
	unoccupied(61, Position),  % f8 is empty
	unoccupied(62, Position),  % g8 is empty
	% king and squares it passes through are not under attack
	not(is_under_attack(60, black, Position)),  % King not in check
	not(is_under_attack(61, black, Position)),  % f8 not under attack
	not(is_under_attack(62, black, Position)).  % g8 not under attack

% Queenside castling (long castling)
castling_move(From, white, Position, To) :-
	From = 4,  % White king starting position
	To = 2,    % King moves to c1 (position 2)
	get_half(Position, half_position(_,_,_,_,_,_,Castle,_), black),
	member(queenside,Castle),
	unoccupied(1, Position),  % b1 is empty
	unoccupied(2, Position),  % c1 is empty
	unoccupied(3, Position),  % d1 is empty
	% Additional check: king and squares it passes through are not under attack
	not(is_under_attack(4, white, Position)),  % King not in check
	not(is_under_attack(3, white, Position)),  % d1 not under attack
	not(is_under_attack(2, white, Position)).  % c1 not under attack

castling_move(From, black, Position, To) :-
	From = 60,  % Black king starting position
	To = 58,    % King moves to c8 (position 58)
	get_half(Position, half_position(_,_,_,_,_,_,Castle,_), black),
	member(queenside,Castle),
	unoccupied(57, Position),  % b8 is empty
	unoccupied(58, Position),  % c8 is empty
	unoccupied(59, Position),  % d8 is empty
	% Additional check: king and squares it passes through are not under attack
	not(is_under_attack(60, black, Position)),  % King not in check
	not(is_under_attack(59, black, Position)),  % d8 not under attack
	not(is_under_attack(58, black, Position)).  % c8 not under attack

% long_move: move for long distance (rook, bishop, queen)
long_move(From,Color,Type,Position,To):-
	poss_move(Type,Direction),
	multiple_steps(From,Direction,To,Color,Position).

% short_move: move for one step (king, knight)
short_move(From,Color,Type,Position,To):-
	poss_move(Type,Direction),
	one_step(From,Direction,To,Color,Position).

% =================================
% Pawn promotion
% =================================

% check if position is on promotion rank
is_promotion_rank(Pos, white) :-
	between(56, 63, Pos).  % 8th rank for white
is_promotion_rank(Pos, black) :-
	between(0, 7, Pos).    % 1st rank for black

% check if a pawn move results in promotion
is_promotion_move(From, To, Color, Position) :-
	find_piece_type(From, pawn, Position, Color),
	is_promotion_rank(To, Color).

% promote_pawn: remove pawn and add promoted piece
promote_pawn(Position, Color, PawnPos, PromotionPiece, NewPosition) :-
	% Remove the pawn
	get_half(Position, Half, Color),
	extract(Half, pawn, PawnList),
	remove(PawnPos, PawnList, NewPawnList),
	combine(Half, pawn, NewPawnList, TempHalf),
	
	% Add the promoted piece
	extract(TempHalf, PromotionPiece, PieceList),
	combine(TempHalf, PromotionPiece, [PawnPos|PieceList], NewHalf),
	
	% Update the position
	update_half(Position, NewHalf, Color, NewPosition).

bot_promotion(queen).
bot_promotion(knight).
% promotion choice
get_promotion_choice(PromotionPiece, Color) :-
	human(Color),
    state(place),
    write('Choose promotion piece (q/r/b/k): '),
    get_char(Input),
    (   Input = 'q' -> PromotionPiece = queen
    ;   Input = 'r' -> PromotionPiece = rook  
    ;   Input = 'b' -> PromotionPiece = bishop
    ;   Input = 'k' -> PromotionPiece = knight
    ;   (write('Invalid choice, promoting to queen.'), nl,
        PromotionPiece = queen)
    ),!.

get_promotion_choice(PromotionPiece, _Color) :-
	bot_promotion(PromotionPiece).

% =================================
% Pawn enpassant
% =================================
% En passant move - white pawn
is_enpassant_move(From, To, white, Position) :-
	between(32, 39, From),    % White pawn on 5th rank
	between(40, 47, To),      % Moving to 6th rank
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), white),
	member(OpponentPawnPos, EnpassantList),  % Get opponent pawn position
	abs(To - OpponentPawnPos) =:= 8.         % Target square is 8 squares away from opponent pawn

% En passant move - black pawn
is_enpassant_move(From, To, black, Position) :-
	between(24, 31, From),    % Black pawn on 4th rank
	between(16, 23, To),      % Moving to 3rd rank
	get_half(Position, half_position(_,_,_,_,_,_,_,EnpassantList), black),
	member(OpponentPawnPos, EnpassantList),  % Get opponent pawn position
	abs(To - OpponentPawnPos) =:= 8.         % Target square is 8 squares away from opponent pawn