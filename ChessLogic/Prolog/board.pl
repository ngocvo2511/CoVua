% =================================
% Board utilities
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
