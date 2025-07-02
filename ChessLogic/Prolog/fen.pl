% Entry point: convert a FEN string to your custom format
convert_fen_to_position(FEN) :-
    split_string(FEN, " ", "", [BoardStr, _, CastlingStr | _]),
    fen_board(BoardStr, Pieces),
    extract_half_position(white, Pieces, WPawn, WRook, WKnight, WBishop, WQueen, WKing),
    extract_half_position(black, Pieces, BPawn, BRook, BKnight, BBishop, BQueen, BKing),
    castling_list(CastlingStr, WhiteCastling, BlackCastling),
    format('initial_pos(position(H1, H2)) :-~n'),
    format('    PawnWhite = ~w,~n', [WPawn]),
    format('    H1 = half_position(PawnWhite, ~w, ~w, ~w, ~w, ~w, ~w, []),~n',
           [WRook, WKnight, WBishop, WQueen, WKing, WhiteCastling]),
    format('    PawnBlack = ~w,~n', [BPawn]),
    format('    H2 = half_position(PawnBlack, ~w, ~w, ~w, ~w, ~w, ~w, []).~n',
           [BRook, BKnight, BBishop, BQueen, BKing, BlackCastling]).

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
    number_string(N, C),
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
    findall(I, member(piece(Side, pawn, I), Pieces), Pawns),
    findall(I, member(piece(Side, rook, I), Pieces), Rooks),
    findall(I, member(piece(Side, knight, I), Pieces), Knights),
    findall(I, member(piece(Side, bishop, I), Pieces), Bishops),
    findall(I, member(piece(Side, queen, I), Pieces), Queens),
    findall(I, member(piece(Side, king, I), Pieces), KingsList),
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
