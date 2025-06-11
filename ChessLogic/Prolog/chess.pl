:- dynamic 
	human/1, % human player color, if predicate not exist then bot will play that turn
	board/2. % board state, color

initial_pos(position(H1,H2,0)):-
	PawnWhite = [9,10,12,13,14,15],
	H1 = half_position(PawnWhite,[0,7],[1,6],[2,5],[3],[4],notmoved),
	PawnBlack = [48,49,50,51,52,53,54,55],
	H2 = half_position(PawnBlack,[56,63],[57,62],[58,61],[59],[60],notmoved).

% =================================
% player queries
% =================================
% human vs human
% human vs computer
% computer vs human
% computer vs computer
game_mode(hxh) :- asserta(human(white)), asserta(human(black)) ,!.
game_mode(hxc) :- asserta(human(white)), !.
game_mode(cxh) :- asserta(human(black)), !.
game_mode(cxc) :- !.

% update the whole board, can be use for reset
set_position(begin) :-
	retractall(board(_,_)),
	initial_pos(Position),
	asserta(board(Position,white)),!.
set_position(Position,Color) :- 
	retractall(board(_,_)), 
	asserta(board(Position,Color)),!.

reset:-
	retractall(board(_,_)),
	retractall(human(_)).

% =================================
% Utility predicates
% =================================

% invalid_field(X): X is invalid position for 0-63 board
invalid_field(X):-
	X < 0,!.
invalid_field(X):-
	X > 63,!.

% get_half: get half position for one side
get_half(position(Half,_,_),Half,white).
get_half(position(_,Half,_),Half,black).

% exist: check if there is a piece of certain type in the field
exist(Field,half_position(X,_,_,_,_,_,_),pawn):-
	member(Field,X).
exist(Field,half_position(_,X,_,_,_,_,_),rook):-
	member(Field,X).
exist(Field,half_position(_,_,X,_,_,_,_),knight):-
	member(Field,X).
exist(Field,half_position(_,_,_,X,_,_,_),bishop):-
	member(Field,X).
exist(Field,half_position(_,_,_,_,X,_,_),queen):-
	member(Field,X).
exist(Field,half_position(_,_,_,_,_,X,_),king):-
	member(Field,X).

% occupied: true if there is a piece in the Field
occupied(Field,white,position(Stones,_,_)):- exist(Field,Stones,_).	
occupied(Field,black,Position):- 
	Position = position(_,Stones,_),
	exist(Field,Stones,_).

% unoccupied: true if the position is valid and not occupied by any piece
unoccupied(Field,Position):-
	not(occupied(Field,white,Position)),
	not(occupied(Field,black,Position)),
	not(invalid_field(Field)).

% invert: between black and white
invert(white,black).
invert(black,white).

% find_piece_color: determine which color owns the piece at given position
find_piece_color(Pos,Color,Position) :-
	occupied(Pos,white,Position),
	Color = white,!.
find_piece_color(Pos,Color,Position) :-
	occupied(Pos,black,Position),
	Color = black,!.

% find_piece_type: determine the type of piece at given position
find_piece_type(Pos,Type,Position,Color) :-
	get_half(Position,Half,Color),
	exist(Pos,Half,Type).

% =================================
% Check and Attack Detection
% =================================

% find_king: find the position of king for given color
find_king(Position, Color, KingPos) :-
	get_half(Position, half_position(_,_,_,_,_,[KingPos],_), Color).

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
in_check(Color, Position) :-
	find_king(Position, Color, KingPos),
	is_under_attack(KingPos, Color, Position).

% =================================
% Legal Move Validation with Check
% =================================

% is_legal_move: check if a move is legal (doesn't leave king in check)
is_legal_move(From, To, Color, Position) :-
	% First check if the basic move is valid
	find_piece_type(From, Type, Position, Color),
	legal_move_for_piece(From, To, Type, Color, Position),
	% Then simulate the move and check if king is still safe
	simulate_move(From, To, Color, Position, NewPosition),
	not(in_check(Color, NewPosition)).

% simulate_move: create a new position after making a move
simulate_move(From, To, Color, Position, NewPosition) :-
	find_piece_type(From, Type, Position, Color),
	
	% Check if this is a castling move
	(   (Type = king, is_castling_move(Color, From, To)) ->
	    % Handle castling
	    castle_move(Position, Color, From, To, NewPosition)
	;   % Check if there's an opponent piece to capture
	    (   occupied(To, OpponentColor, Position),
	        invert(Color, OpponentColor) ->
	        % Capture move: remove opponent piece first, then move our piece
	        capture_piece(Position, OpponentColor, To, TempPosition),
	        move_piece(TempPosition, Color, From, To, NewPosition)
	    ;   % Normal move: just move our piece
	        move_piece(Position, Color, From, To, NewPosition)
	    )
	).

% get_all_legal_moves: get all legal moves for a color
get_all_legal_moves(Color, Position, LegalMoves) :-
	findall([From,To], 
	        (get_half(Position, Half, Color),
	         get_piece_position(Half, From, _),
	         find_piece_type(From, Type, Position, Color),
	         legal_move_for_piece(From, To, Type, Color, Position),
	         is_legal_move(From, To, Color, Position)),
	        LegalMoves).

% get_piece_position: get all piece positions from half position
get_piece_position(half_position(Pawns,_,_,_,_,_,_), Pos, pawn) :- member(Pos, Pawns).
get_piece_position(half_position(_,Rooks,_,_,_,_,_), Pos, rook) :- member(Pos, Rooks).
get_piece_position(half_position(_,_,Knights,_,_,_,_), Pos, knight) :- member(Pos, Knights).
get_piece_position(half_position(_,_,_,Bishops,_,_,_), Pos, bishop) :- member(Pos, Bishops).
get_piece_position(half_position(_,_,_,_,Queens,_,_), Pos, queen) :- member(Pos, Queens).
get_piece_position(half_position(_,_,_,_,_,Kings,_), Pos, king) :- member(Pos, Kings).

% is_checkmate: check if the given color is in checkmate
is_checkmate(Color, Position) :-
	in_check(Color, Position),
	get_all_legal_moves(Color, Position, []).  % No legal moves available

% is_stalemate: check if the given color is in stalemate
is_stalemate(Color, Position) :-
	not(in_check(Color, Position)),
	get_all_legal_moves(Color, Position, []).  % No legal moves but not in check

% =================================
% Movement predicates
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
	not(invalid_field(Next)),
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

% Pawn movement rules (adjusted for 0-63 board)
pawn_move(From,white,Position,To):-
	To is From + 7,  % capture diagonal left
	not(invalid_field(To)),
	not(crosses_edge(From,To,7)),
	occupied(To,black,Position).
pawn_move(From,white,Position,To):-
	To is From + 8,  % move forward
	not(invalid_field(To)),
	unoccupied(To,Position).
pawn_move(From,white,Position,To):-
	To is From + 9,  % capture diagonal right
	not(invalid_field(To)),
	not(crosses_edge(From,To,9)),
	occupied(To,black,Position).
pawn_move(From,white,Position,To):-
	To is From + 16, % double move from starting position
	not(invalid_field(To)),
	unoccupied(To,Position),
	unoccupied(From + 8,Position),
	From >= 8, From =< 15. % starting row for white pawns

pawn_move(From,black,Position,To):-
	To is From - 7,  % capture diagonal right
	not(invalid_field(To)),
	not(crosses_edge(From,To,-7)),
	occupied(To,white,Position).
pawn_move(From,black,Position,To):-
	To is From - 8,  % move forward
	not(invalid_field(To)),
	unoccupied(To,Position).
pawn_move(From,black,Position,To):-
	To is From - 9,  % capture diagonal left
	not(invalid_field(To)),
	not(crosses_edge(From,To,-9)),
	occupied(To,white,Position).
pawn_move(From,black,Position,To):-
	To is From - 16, % double move from starting position
	not(invalid_field(To)),
	unoccupied(To,Position),
	unoccupied(From - 8,Position),
	From >= 48, From =< 55. % starting row for black pawns

% =================================
% Castling rules
% =================================

% Check if piece hasn't moved (still has 'notmoved' status)
piece_not_moved(Position, Color) :-
	get_half(Position, half_position(_,_,_,_,_,_,notmoved), Color).

% Kingside castling (short castling)
castling_move(From, Color, Position, To) :-
	Color = white,
	From = 4,  % White king starting position
	To = 6,    % King moves to g1 (position 6)
	piece_not_moved(Position, white),  % King hasn't moved
	get_half(Position, half_position(_,Rooks,_,_,_,_,_), white),
	member(7, Rooks),  % Kingside rook is still there (h1 = position 7)
	unoccupied(5, Position),  % f1 is empty
	unoccupied(6, Position),  % g1 is empty
	% Additional check: king and squares it passes through are not under attack
	not(is_under_attack(4, white, Position)),  % King not in check
	not(is_under_attack(5, white, Position)),  % f1 not under attack
	not(is_under_attack(6, white, Position)).  % g1 not under attack

castling_move(From, Color, Position, To) :-
	Color = black,
	From = 60,  % Black king starting position
	To = 62,    % King moves to g8 (position 62)
	piece_not_moved(Position, black),  % King hasn't moved
	get_half(Position, half_position(_,Rooks,_,_,_,_,_), black),
	member(63, Rooks),  % Kingside rook is still there (h8 = position 63)
	unoccupied(61, Position),  % f8 is empty
	unoccupied(62, Position),  % g8 is empty
	% Additional check: king and squares it passes through are not under attack
	not(is_under_attack(60, black, Position)),  % King not in check
	not(is_under_attack(61, black, Position)),  % f8 not under attack
	not(is_under_attack(62, black, Position)).  % g8 not under attack

% Queenside castling (long castling)
castling_move(From, Color, Position, To) :-
	Color = white,
	From = 4,  % White king starting position
	To = 2,    % King moves to c1 (position 2)
	piece_not_moved(Position, white),  % King hasn't moved
	get_half(Position, half_position(_,Rooks,_,_,_,_,_), white),
	member(0, Rooks),  % Queenside rook is still there (a1 = position 0)
	unoccupied(1, Position),  % b1 is empty
	unoccupied(2, Position),  % c1 is empty
	unoccupied(3, Position),  % d1 is empty
	% Additional check: king and squares it passes through are not under attack
	not(is_under_attack(4, white, Position)),  % King not in check
	not(is_under_attack(3, white, Position)),  % d1 not under attack
	not(is_under_attack(2, white, Position)).  % c1 not under attack

castling_move(From, Color, Position, To) :-
	Color = black,
	From = 60,  % Black king starting position
	To = 58,    % King moves to c8 (position 58)
	piece_not_moved(Position, black),  % King hasn't moved
	get_half(Position, half_position(_,Rooks,_,_,_,_,_), black),
	member(56, Rooks),  % Queenside rook is still there (a8 = position 56)
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
% Main pick_piece predicate (updated with check validation)
% =================================

% pick_piece(Pos, LegalMoves) - returns list of all legal moves for piece at Pos
pick_piece(Pos, LegalMoves) :-
	board(Position, Color),
	find_piece_color(Pos, Color, Position),
	find_piece_type(Pos, Type, Position, Color),
	findall(To, is_legal_move(Pos, To, Color, Position), LegalMoves).

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

% =================================
% Board manipulation predicates
% =================================

% extract: extract certain type of pieces from half position
extract(half_position(X,_,_,_,_,_,_),pawn,X).
extract(half_position(_,X,_,_,_,_,_),rook,X).
extract(half_position(_,_,X,_,_,_,_),knight,X).
extract(half_position(_,_,_,X,_,_,_),bishop,X).
extract(half_position(_,_,_,_,X,_,_),queen,X).
extract(half_position(_,_,_,_,_,X,_),king,X).

% combine: combine new piece list with original half position
combine(half_position(_,B,C,D,E,F,G),pawn,N,half_position(N,B,C,D,E,F,G)).
combine(half_position(A,_,C,D,E,F,G),rook,N,half_position(A,N,C,D,E,F,G)).
combine(half_position(A,B,_,D,E,F,G),knight,N,half_position(A,B,N,D,E,F,G)).
combine(half_position(A,B,C,_,E,F,G),bishop,N,half_position(A,B,C,N,E,F,G)).
combine(half_position(A,B,C,D,_,F,G),queen,N,half_position(A,B,C,D,N,F,G)).
combine(half_position(A,B,C,D,E,_,G),king,N,half_position(A,B,C,D,E,N,G)).

% remove element from list
remove(X,[X|New],New):- !.
remove(X,[A|Old],[A|New]):-
	remove(X,Old,New).

% update_half: update half position in full position
update_half(position(_,Y,Z),Half,white,position(Half,Y,Z)).
update_half(position(X,_,Z),Half,black,position(X,Half,Z)).

% mark_piece_moved: change 'notmoved' status to 'moved' for a piece
mark_piece_moved(half_position(P,R,N,B,Q,K,notmoved), half_position(P,R,N,B,Q,K,moved)).
mark_piece_moved(Half, Half). % If already moved, no change

% move_piece: move a piece from one position to another within same color
move_piece(Position, Color, From, To, NewPosition) :-
	get_half(Position, Half, Color),
	find_piece_type(From, Type, Position, Color),
	extract(Half, Type, List),
	remove(From, List, TempList),
	combine(Half, Type, [To|TempList], TempHalf),
	% Mark piece as moved if it's king or rook
	(   (Type = king ; Type = rook) ->
	    mark_piece_moved(TempHalf, NewHalf)
	;   NewHalf = TempHalf
	),
	update_half(Position, NewHalf, Color, NewPosition).

% castle_move: special handling for castling moves
castle_move(Position, Color, KingFrom, KingTo, NewPosition) :-
	% Determine rook positions based on castling type
	(   % Kingside castling
	    (Color = white, KingFrom = 4, KingTo = 6) ->
	    RookFrom = 7, RookTo = 5
	;   (Color = black, KingFrom = 60, KingTo = 62) ->
	    RookFrom = 63, RookTo = 61
	;   % Queenside castling  
	    (Color = white, KingFrom = 4, KingTo = 2) ->
	    RookFrom = 0, RookTo = 3
	;   (Color = black, KingFrom = 60, KingTo = 58) ->
	    RookFrom = 56, RookTo = 59
	),
	
	% Move king first
	move_piece(Position, Color, KingFrom, KingTo, TempPosition),
	% Then move rook
	move_piece(TempPosition, Color, RookFrom, RookTo, NewPosition).

% is_castling_move: check if a king move is a castling move
is_castling_move(Color, From, To) :-
	Color = white,
	From = 4,
	(To = 6 ; To = 2).  % Kingside or queenside castling
is_castling_move(Color, From, To) :-
	Color = black,
	From = 60,
	(To = 62 ; To = 58).  % Kingside or queenside castling

% capture_piece: remove opponent piece from position
capture_piece(Position, Color, CapturePos, NewPosition) :-
	get_half(Position, Half, Color),
	find_piece_type(CapturePos, Type, Position, Color),
	extract(Half, Type, List),
	remove(CapturePos, List, NewList),
	combine(Half, Type, NewList, NewHalf),
	update_half(Position, NewHalf, Color, NewPosition).

% =================================
% Enhanced place_piece with game state checking
% =================================

% place_piece: main predicate to move piece from From to To with full validation
place_piece(From, To) :-
	board(Position, Color),
	
	% Check if it's a legal move
	is_legal_move(From, To, Color, Position),
	
	% Make the move
	simulate_move(From, To, Color, Position, NewPosition),
	
	% Switch to opposite player's turn
	invert(Color, NextColor),
	
	% Check for game ending conditions
	(   is_checkmate(NextColor, NewPosition) ->
	    % Current player wins by checkmate
	    write('CHECKMATE'), nl,
	    reset
	;   is_stalemate(NextColor, NewPosition) ->
	    % Game ends in stalemate
	    write('STALEMATE'), nl,
	    reset
	;   % Game continues normally
	    (   in_check(NextColor, NewPosition) ->
	        write('CHECK'), nl
	    ;   true
	    ),
	    % Update the board
	    retract(board(Position, Color)),
	    asserta(board(NewPosition, NextColor))
	).

skip_turn:- board(Position, Color),invert(Color, NextColor),
		retract(board(Position, Color)),
	    asserta(board(Position, NextColor)).

% check_game_status: helper predicate to check current game status
check_game_status :-
	board(Position, Color),
	(   in_check(Color, Position) ->
	    (   is_checkmate(Color, Position) ->
	        invert(Color, Winner),
	        write('CHECKMATE'), nl,
	        reset
	    ;   write('CHECK'), nl
	    )
	;   is_stalemate(Color, Position) ->
	    write('STALEMATE'), nl,
	    reset
	;   write(' to move.'), nl
	).

% =================================
% Helper predicates for testing
% =================================

% Test check detection
test_check :-
	only_king_and_rooks(Position),
	set_position(Position,white),
	write('Testing check detection:'), nl,
	board(Pos, _),
	write('White king in check: '),
	(in_check(white, Pos) -> write('Yes') ; write('No')), nl,
	write('Black king in check: '),
	(in_check(black, Pos) -> write('Yes') ; write('No')), nl.


only_king_and_rooks(position(H1, H2, 0)) :-
    H1 = half_position([], [0, 7], [], [], [], [4], notmoved),
    H2 = half_position([], [56, 63], [], [], [], [60], notmoved).