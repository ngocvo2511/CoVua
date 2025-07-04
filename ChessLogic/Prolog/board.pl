% =================================
% Board utilities
% =================================

% X is valid position for 0-63 board
valid_field(X) :-
	between(0, 63, X).

% get_half: get half position for one side
get_half(position(Half,_),Half,white).
get_half(position(_,Half),Half,black).

% exist: check if there is a piece of certain type in the field
exist(Field,half_position(X,_,_,_,_,_,_,_),pawn):-
	member(Field,X).
exist(Field,half_position(_,X,_,_,_,_,_,_),rook):-
	member(Field,X).
exist(Field,half_position(_,_,X,_,_,_,_,_),knight):-
	member(Field,X).
exist(Field,half_position(_,_,_,X,_,_,_,_),bishop):-
	member(Field,X).
exist(Field,half_position(_,_,_,_,X,_,_,_),queen):-
	member(Field,X).
exist(Field,half_position(_,_,_,_,_,X,_,_),king):-
	member(Field,X).

% =================================
% Board manipulation predicates
% =================================

% extract type of pieces from half position
extract(half_position(X,_,_,_,_,_,_,_),pawn,X).
extract(half_position(_,X,_,_,_,_,_,_),rook,X).
extract(half_position(_,_,X,_,_,_,_,_),knight,X).
extract(half_position(_,_,_,X,_,_,_,_),bishop,X).
extract(half_position(_,_,_,_,X,_,_,_),queen,X).
extract(half_position(_,_,_,_,_,X,_,_),king,X).
% extract type of right from half position
extract(half_position(_,_,_,_,_,_,X,_),castle,X).
extract(half_position(_,_,_,_,_,_,_,X),enpassant,X).

% combine: combine new piece list with original half position
combine(half_position(_,B,C,D,E,F,G,H),pawn,N,half_position(N,B,C,D,E,F,G,H)).
combine(half_position(A,_,C,D,E,F,G,H),rook,N,half_position(A,N,C,D,E,F,G,H)).
combine(half_position(A,B,_,D,E,F,G,H),knight,N,half_position(A,B,N,D,E,F,G,H)).
combine(half_position(A,B,C,_,E,F,G,H),bishop,N,half_position(A,B,C,N,E,F,G,H)).
combine(half_position(A,B,C,D,_,F,G,H),queen,N,half_position(A,B,C,D,N,F,G,H)).
combine(half_position(A,B,C,D,E,_,G,H),king,N,half_position(A,B,C,D,E,N,G,H)).
% combine: combine new right list with original right
combine(half_position(A,B,C,D,E,F,_,H),castle,N,half_position(A,B,C,D,E,F,N,H)).
combine(half_position(A,B,C,D,E,F,G,_),enpassant,N,half_position(A,B,C,D,E,F,G,N)).

% remove element from list
remove(_,[],[]).
remove(X,[X|New],New):- !.
remove(X,[A|Old],[A|New]):-
	remove(X,Old,New).

% update_half: update half position in full position
update_half(position(_,Y),Half,white,position(Half,Y),_BoardList,_AttackData).
update_half(position(X,_),Half,black,position(X,Half),_BoardList,_AttackData).

combine_half(H1,H2,white,position(H1,H2)).
combine_half(H1,H2,black,position(H2,H1)).

% move_piece: move a piece from one position to another within same color
move_piece(Position, Color, From, To, NewPosition, BoardList, AttackData) :-
	invert(Color, OpponentColor),
    get_half(Position, Half, Color),
    get_half(Position, OpponentHalf, OpponentColor),
    nth0(From, BoardList, [Type, _]),
    extract(Half, Type, PieceList),
    extract(Half, castle, CastleList),
    remove(From, PieceList, TempList),
    combine(Half, Type, [To|TempList], Temp1Half),
	
    (	(Type = king, (From = 4 ; From = 60)) ->
            combine(Temp1Half, castle, [], Temp2Half)
    ;   (Type = rook, (From = 0 ; From = 56)) ->
            remove(queenside, CastleList, TempCastleList),
            combine(Temp1Half, castle, TempCastleList, Temp2Half)
    ;   (Type = rook, (From = 7 ; From = 63)) ->
            remove(kingside, CastleList, TempCastleList),
            combine(Temp1Half, castle, TempCastleList, Temp2Half)
    ;   Temp2Half = Temp1Half
    ),
	% Enpassant only last for 1 move
	combine(Temp2Half, enpassant, [], Temp3Half),

	(	(Type = pawn, abs(To-From) =:= 16) -> 
		combine(OpponentHalf, enpassant, [To], OpponentNewHalf),
		combine_half(Temp3Half, OpponentNewHalf, Color, NewPosition)
	;	update_half(Position, Temp3Half, Color, NewPosition, BoardList, AttackData)
	).

% actually moving the piece for castling moves
castle_piece(Position, Color, KingFrom, KingTo, NewPosition, BoardList, AttackData) :-
	
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
	move_piece(Position, Color, KingFrom, KingTo, TempPosition, BoardList, AttackData),
	% Then move rook
	move_piece(TempPosition, Color, RookFrom, RookTo, NewPosition, BoardList, AttackData).

% quick check if king castling
is_castling_move(white, 4, 2, _BoardList, _AttackData).
is_castling_move(white, 4, 6, _BoardList, _AttackData).
is_castling_move(black, 60, 58, _BoardList, _AttackData).
is_castling_move(black, 60, 62, _BoardList, _AttackData).

% remove opponent piece from position (color is opponent)
capture_piece(Position, Color, CapturePos, NewPosition, BoardList, AttackData) :-
    get_half(Position, Half, Color),
    nth0(CapturePos, BoardList, [Type, _]),
    extract(Half, Type, PieceList),
    extract(Half, castle, CastleList),
    
    remove(CapturePos, PieceList, TempList),
    combine(Half, Type, TempList, Temp1Half),
    (
        (Type = rook, (CapturePos = 0 ; CapturePos = 56)) ->
            remove(queenside, CastleList, TempCastleList),
            combine(Temp1Half, castle, TempCastleList, Temp2Half)
    ;   (Type = rook, (CapturePos = 7 ; CapturePos = 63)) ->
            remove(kingside, CastleList, TempCastleList),
            combine(Temp1Half, castle, TempCastleList, Temp2Half)
    ;   Temp2Half = Temp1Half
    ),
    update_half(Position, Temp2Half, Color, NewPosition, BoardList, AttackData).

% is_fifty_move: check if fifty move rule applies (100 half-moves)
is_fifty_move(Counter) :-
    Counter >= 100.

% reset_fifty_move_counter: reset counter when pawn moves or piece is captured
reset_fifty_move_counter(0).

% increment_fifty_move_counter: increment counter when no pawn move or capture
increment_fifty_move_counter(OldCounter, NewCounter) :-
    NewCounter is OldCounter + 1.

% check_pawn_move: check if the moved piece is a pawn
check_pawn_move(From, _Position, Color, BoardList, _AttackData) :-
    nth0(From, BoardList, [pawn, Color]).

% check_capture: check if a piece was captured in the move
check_capture(To, _Position, Color, BoardList, _AttackData) :-
    invert(Color, OpponentColor),
    nth0(To, BoardList, [_Type, OpponentColor]).

% update_fifty_move_counter: update counter based on move type
update_fifty_move_counter(From, To, Position, Color, OldCounter, NewCounter, BoardList, AttackData) :-
    (check_pawn_move(From, Position, Color, BoardList, AttackData) ; check_capture(To, Position, Color, BoardList, AttackData)) ->
        reset_fifty_move_counter(NewCounter)
    ;   increment_fifty_move_counter(OldCounter, NewCounter).