% Bidirectional: convert between FEN string and Position/Color/Counter
% Mode 1: FEN string to Position/Color/Counter
convert_fen_to_position(FEN, Position, Color, Counter) :-
    nonvar(FEN), var(Position),
    !,
    % Forward direction: FEN -> Position/Color/Counter
    % Convert string to atom if needed for compatibility
    (is_list(FEN) -> atom_codes(FENAtom, FEN) ; FENAtom = FEN),
    atomic_list_concat([BoardStr, ActiveColorStr, CastlingStr, EnPassantStr, HalfmoveStr | _], ' ', FENAtom),
    fen_board(BoardStr, Pieces),
    extract_half_position(white, Pieces, WPawn, WRook, WKnight, WBishop, WQueen, WKing),
    extract_half_position(black, Pieces, BPawn, BRook, BKnight, BBishop, BQueen, BKing),
    castling_list(CastlingStr, WhiteCastling, BlackCastling),
    parse_enpassant(EnPassantStr, ActiveColorStr, WhiteEnPassant, BlackEnPassant),
    atom_number(HalfmoveStr, Counter),
    parse_active_color(ActiveColorStr, Color),
    % Create the actual position structure
    H1 = half_position(WPawn, WRook, WKnight, WBishop, WQueen, WKing, WhiteCastling, WhiteEnPassant),
    H2 = half_position(BPawn, BRook, BKnight, BBishop, BQueen, BKing, BlackCastling, BlackEnPassant),
    Position = position(H1, H2).

% Mode 2: Position/Color/Counter to FEN string
convert_fen_to_position(FEN, Position, Color, Counter) :-
    var(FEN), nonvar(Position),
    !,
    % Reverse direction: Position/Color/Counter -> FEN
    position_to_fen_string(Position, Color, Counter, FEN).

% Helper predicate to convert position back to FEN string
position_to_fen_string(position(H1, H2), Color, Counter, FEN) :-
    % Extract piece positions
    H1 = half_position(WPawn, WRook, WKnight, WBishop, WQueen, WKing, WhiteCastling, WhiteEnPassant),
    H2 = half_position(BPawn, BRook, BKnight, BBishop, BQueen, BKing, BlackCastling, BlackEnPassant),
    
    % Create board string
    create_board_string(H1, H2, BoardStr),
    
    % Create active color string
    (Color = white -> ActiveColorStr = "w" ; ActiveColorStr = "b"),
    
    % Create castling string
    create_castling_string(WhiteCastling, BlackCastling, CastlingStr),
    
    % Create en passant string
    create_enpassant_string(WhiteEnPassant, BlackEnPassant, Color, EnPassantStr),
    
    % Convert counter to string
    atom_number(CounterStr, Counter),
    
    % Combine into FEN string
    atomic_list_concat([BoardStr, ActiveColorStr, CastlingStr, EnPassantStr, CounterStr, "1"], " ", FEN).

% Helper to create board string from positions (simplified version)
create_board_string(H1, H2, BoardStr) :-
    % This is a simplified placeholder - you'd need to implement the full logic
    % to convert piece positions back to FEN board notation
    BoardStr = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR".

% Helper to create castling string
create_castling_string(WhiteCastling, BlackCastling, CastlingStr) :-
    append(WhiteCastling, BlackCastling, AllCastling),
    (AllCastling = [] -> 
        CastlingStr = "-" 
    ; 
        create_castling_chars(WhiteCastling, BlackCastling, Chars),
        atomic_list_concat(Chars, "", CastlingStr)
    ).

create_castling_chars(WhiteCastling, BlackCastling, Chars) :-
    (member(kingside, WhiteCastling) -> W1 = ['K'] ; W1 = []),
    (member(queenside, WhiteCastling) -> W2 = ['Q'|W1] ; W2 = W1),
    (member(kingside, BlackCastling) -> B1 = ['k'] ; B1 = []),
    (member(queenside, BlackCastling) -> B2 = ['q'|B1] ; B2 = B1),
    append(W2, B2, Chars).

% Helper to create en passant string
create_enpassant_string([], [], _, "-") :- !.
create_enpassant_string([Pos], [], white, EnPassantStr) :- 
    !, position_to_algebraic(Pos, EnPassantStr).
create_enpassant_string([], [Pos], black, EnPassantStr) :- 
    !, position_to_algebraic(Pos, EnPassantStr).
create_enpassant_string(_, _, _, "-").

% Helper to convert position back to algebraic notation
position_to_algebraic(Pos, AlgebraicStr) :-
    flip_horizontal_pos(Pos, OriginalPos),
    Col is OriginalPos mod 8,
    Row is OriginalPos // 8,
    file_to_column(FileChar, Col),
    rank_to_row(RankChar, Row),
    atomic_list_concat([FileChar, RankChar], "", AlgebraicStr).

% Alternative entry point that also prints the position (for debugging)
convert_fen_to_position_debug(FEN) :-
    convert_fen_to_position(FEN, Position, Color, Counter),
    Position = position(H1, H2),
    H1 = half_position(WPawn, WRook, WKnight, WBishop, WQueen, WKing, WhiteCastling, WhiteEnPassant),
    H2 = half_position(BPawn, BRook, BKnight, BBishop, BQueen, BKing, BlackCastling, BlackEnPassant),
    format('Position: ~w~n', [Position]),
    format('Active Color: ~w, Counter: ~w~n', [Color, Counter]),
    format('White: Pawns=~w, Rooks=~w, Knights=~w, Bishops=~w, Queens=~w, Kings=~w, Castling=~w, EnPassant=~w~n',
           [WPawn, WRook, WKnight, WBishop, WQueen, WKing, WhiteCastling, WhiteEnPassant]),
    format('Black: Pawns=~w, Rooks=~w, Knights=~w, Bishops=~w, Queens=~w, Kings=~w, Castling=~w, EnPassant=~w~n',
           [BPawn, BRook, BKnight, BBishop, BQueen, BKing, BlackCastling, BlackEnPassant]).

% Parses board string into list of piece(Side, Type, Index)
fen_board(BoardStr, Pieces) :-
    string_chars(BoardStr, Chars),
    fen_board_chars(Chars, 0, Pieces).

% Map FEN characters to pieces and indices
fen_board_chars([], _, []).
fen_board_chars(['/'|T], Index, Result) :-
    fen_board_chars(T, Index, Result).
fen_board_chars([C|T], Index, Result) :-
    char_type(C, digit),
    atom_number(C, N),
    N2 is Index + N,
    fen_board_chars(T, N2, Result).
fen_board_chars([C|T], Index, [piece(Side, Type, Index)|Result]) :-
    piece_char(C, Side, Type),
    I2 is Index + 1,
    fen_board_chars(T, I2, Result).

% FEN character to piece type and side
piece_char('P', white, pawn).
piece_char('N', white, knight).
piece_char('B', white, bishop).
piece_char('R', white, rook).
piece_char('Q', white, queen).
piece_char('K', white, king).
piece_char('p', black, pawn).
piece_char('n', black, knight).
piece_char('b', black, bishop).
piece_char('r', black, rook).
piece_char('q', black, queen).
piece_char('k', black, king).

% Extract half position by side
extract_half_position(Side, Pieces, Pawns, Rooks, Knights, Bishops, Queens, Kings) :-
    findall(I, (member(piece(Side, pawn, II), Pieces), flip_horizontal_pos(II, I)), Pawns),
    findall(I, (member(piece(Side, rook, II), Pieces), flip_horizontal_pos(II, I)), Rooks),
    findall(I, (member(piece(Side, knight, II), Pieces), flip_horizontal_pos(II, I)), Knights),
    findall(I, (member(piece(Side, bishop, II), Pieces), flip_horizontal_pos(II, I)), Bishops),
    findall(I, (member(piece(Side, queen, II), Pieces), flip_horizontal_pos(II, I)), Queens),
    findall(I, (member(piece(Side, king, II), Pieces), flip_horizontal_pos(II, I)), KingsList),
    (KingsList = [K] -> Kings = [K] ; Kings = []).

% Parse castling rights into your internal format
castling_list(Str, W, B) :-
    string_chars(Str, Chars),
    (member('K', Chars) -> W1 = [kingside] ; W1 = []),
    (member('Q', Chars) -> W2 = [queenside|W1] ; W2 = W1),
    reverse(W2, W),
    (member('k', Chars) -> B1 = [kingside] ; B1 = []),
    (member('q', Chars) -> B2 = [queenside|B1] ; B2 = B1),
    reverse(B2, B).

flip_horizontal_pos(Pos, NewPos) :-
    Flip is (Pos mod 8) * 2 + 56,
    NewPos is Flip - Pos.

% Parse en passant square from FEN notation
parse_enpassant("-", _, [], []) :- !.  % No en passant
parse_enpassant(EnPassantStr, ActiveColorStr, WhiteEnPassant, BlackEnPassant) :-
    string_chars(EnPassantStr, [FileChar, RankChar]),
    file_to_column(FileChar, Col),
    rank_to_row(RankChar, Row),
    Square is Row * 8 + Col,
    flip_horizontal_pos(Square, FlippedSquare),
    % Determine which color can capture en passant
    (   ActiveColorStr = "w" ->
        % White to move, so black pawn just moved (white can capture)
        WhiteEnPassant = [FlippedSquare],
        BlackEnPassant = []
    ;   % Black to move, so white pawn just moved (black can capture)
        WhiteEnPassant = [],
        BlackEnPassant = [FlippedSquare]
    ).

% Convert file letter to column number (a=0, b=1, ..., h=7)
file_to_column('a', 0).
file_to_column('b', 1).
file_to_column('c', 2).
file_to_column('d', 3).
file_to_column('e', 4).
file_to_column('f', 5).
file_to_column('g', 6).
file_to_column('h', 7).

% Convert rank character to row number (1=0, 2=1, ..., 8=7)
rank_to_row('1', 0).
rank_to_row('2', 1).
rank_to_row('3', 2).
rank_to_row('4', 3).
rank_to_row('5', 4).
rank_to_row('6', 5).
rank_to_row('7', 6).
rank_to_row('8', 7).

% Parse active color from FEN
parse_active_color("w", white).
parse_active_color("b", black).
