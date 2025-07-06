% Dynamic predicate to store random numbers
:- dynamic random_number/2.  % random_number(Index, Value)
% Dynamic predicates to store Zobrist tables
:- dynamic zobrist_piece/4.      % zobrist_piece(PieceType, Color, Square, Value)
:- dynamic zobrist_castling/2.   % zobrist_castling(CastlingRights, Value)
:- dynamic zobrist_en_passant/2. % zobrist_en_passant(File, Value)
:- dynamic zobrist_side_to_move/1. % zobrist_side_to_move(Value)

% Helper predicate to read all characters from a stream
read_chars(Stream, Chars) :-
    get_char(Stream, Char),
    (   Char = end_of_file ->
        Chars = []
    ;   Chars = [Char|RestChars],
        read_chars(Stream, RestChars)
    ).

% Read random numbers from RandomNumbers.txt file
read_random_numbers :-
    % Clear any existing random numbers
    retractall(random_number(_, _)),
    
    % Read the file
    open('RandomNumbers.txt', read, Stream),
    read_chars(Stream, Chars),
    close(Stream),
    atom_chars(Atom, Chars),
    atom_string(Atom, NumberString),
    
    % Split by commas and convert to numbers
    split_string(NumberString, ',', '', NumberStrings),
    
    % Store each number with its index
    store_random_numbers(NumberStrings, 0).

% Helper predicate to store numbers with indices
store_random_numbers([], _).
store_random_numbers([NumberString|Rest], Index) :-
    number_string(Number, NumberString),
    assertz(random_number(Index, Number)),
    NextIndex is Index + 1,
    store_random_numbers(Rest, NextIndex).

% Get a random number by index
get_random_number(Index, Number) :-
    random_number(Index, Number).

% Initialize all Zobrist tables
initialize_zobrist_tables :-
    read_random_numbers,
    % Clear existing tables
    retractall(zobrist_piece(_, _, _, _)),
    retractall(zobrist_castling(_, _)),
    retractall(zobrist_en_passant(_, _)),
    retractall(zobrist_side_to_move(_)),
    
    % Initialize piece tables
    initialize_piece_tables(0),
    
    % Initialize castling rights table
    initialize_castling_table(0, 1024), % 64*8*2 = 1024 is starting index
    
    % Initialize en passant file table
    initialize_en_passant_table(0, 1040), % 1024 + 16 = 1040 is starting index
    
    % Initialize side to move
    get_random_number(1049, SideToMoveValue), % 1040 + 9 = 1049 is the final index
    assertz(zobrist_side_to_move(SideToMoveValue)).

% Initialize piece tables: piece types, colors, squares
initialize_piece_tables(64) :- !. % Done with all squares
initialize_piece_tables(Square) :-
    initialize_pieces_for_square(Square, [pawn, rook, knight, bishop, queen, king, empty, empty]),
    NextSquare is Square + 1,
    initialize_piece_tables(NextSquare).

% Initialize all piece types for a given square
initialize_pieces_for_square(_, []) :- !. % Done with all piece types
initialize_pieces_for_square(Square, [PieceType|RestPieces]) :-
    % Get numeric index for piece type
    piece_type_index(PieceType, PieceIndex),
    
    % White piece
    WhiteIndex is Square * 16 + PieceIndex * 2,
    get_random_number(WhiteIndex, WhiteValue),
    assertz(zobrist_piece(PieceType, white, Square, WhiteValue)),
    
    % Black piece
    BlackIndex is Square * 16 + PieceIndex * 2 + 1,
    get_random_number(BlackIndex, BlackValue),
    assertz(zobrist_piece(PieceType, black, Square, BlackValue)),
    
    initialize_pieces_for_square(Square, RestPieces).

% Map piece types to numeric indices (matching the C# implementation)
piece_type_index(pawn, 0).
piece_type_index(rook, 1).
piece_type_index(knight, 2).
piece_type_index(bishop, 3).
piece_type_index(queen, 4).
piece_type_index(king, 5).
piece_type_index(empty, 6).   % For empty squares if needed
piece_type_index(empty, 7).   % Additional empty slot

% Initialize castling rights table (16 different castling combinations)
initialize_castling_table(16, _) :- !. % Done with all castling rights
initialize_castling_table(Rights, BaseIndex) :-
    Index is BaseIndex + Rights,
    get_random_number(Index, Value),
    assertz(zobrist_castling(Rights, Value)),
    NextRights is Rights + 1,
    initialize_castling_table(NextRights, BaseIndex).

% Initialize en passant file table (9 entries: 0 = no ep, 1-8 = files a-h)
initialize_en_passant_table(9, _) :- !. % Done with all en passant files
initialize_en_passant_table(File, BaseIndex) :-
    Index is BaseIndex + File,
    get_random_number(Index, Value),
    assertz(zobrist_en_passant(File, Value)),
    NextFile is File + 1,
    initialize_en_passant_table(NextFile, BaseIndex).

% Calculate Zobrist key from current board position
calculate_zobrist_key(Position, Color, BoardList, Key) :-
    position_to_board_list(Position, BoardList),
    zobrist_hash_from_board_list(BoardList, Position, Color, Key).

% Calculate Zobrist key from BoardList and position data
zobrist_hash_from_board_list(BoardList, Position, Color, Key) :-
    % Calculate hash for all pieces on the board
    calculate_pieces_hash(BoardList, 0, PiecesHash),
    
    % Calculate castling rights hash
    calculate_castling_hash(Position, CastlingHash),
    
    % Calculate en passant hash
    calculate_en_passant_hash(Position, EnPassantHash),
    
    % Calculate side to move hash
    calculate_side_to_move_hash(Color, SideToMoveHash),
    
    % Combine all hashes using XOR
    Key is PiecesHash xor CastlingHash xor EnPassantHash xor SideToMoveHash.

% Calculate hash for all pieces on the board
calculate_pieces_hash([], _, 0).
calculate_pieces_hash([Piece|RestBoard], Square, Hash) :-
    NextSquare is Square + 1,
    calculate_pieces_hash(RestBoard, NextSquare, RestHash),
    (   Piece = [PieceType, PieceColor] ->
        zobrist_piece(PieceType, PieceColor, Square, PieceValue),
        Hash is RestHash xor PieceValue
    ;   % Empty square
        Hash = RestHash
    ).

% Calculate castling rights hash
calculate_castling_hash(position(H1, H2), Hash) :-
    H1 = half_position(_, _, _, _, _, _, WhiteCastling, _),
    H2 = half_position(_, _, _, _, _, _, BlackCastling, _),
    
    % Convert castling rights to numeric value (0-15)
    castling_rights_to_number(WhiteCastling, BlackCastling, CastlingRights),
    zobrist_castling(CastlingRights, Hash).

% Convert castling rights lists to a 4-bit number
castling_rights_to_number(WhiteCastling, BlackCastling, Number) :-
    (member(kingside, WhiteCastling) -> WhiteKingside = 1 ; WhiteKingside = 0),
    (member(queenside, WhiteCastling) -> WhiteQueenside = 2 ; WhiteQueenside = 0),
    (member(kingside, BlackCastling) -> BlackKingside = 4 ; BlackKingside = 0),
    (member(queenside, BlackCastling) -> BlackQueenside = 8 ; BlackQueenside = 0),
    Number is WhiteKingside + WhiteQueenside + BlackKingside + BlackQueenside.

% Calculate en passant hash
calculate_en_passant_hash(position(H1, H2), Hash) :-
    H1 = half_position(_, _, _, _, _, _, _, WhiteEnPassant),
    H2 = half_position(_, _, _, _, _, _, _, BlackEnPassant),
    
    % Find en passant file (if any)
    (   WhiteEnPassant = [EnPassantSquare|_] ->
        en_passant_square_to_file(EnPassantSquare, File)
    ;   BlackEnPassant = [EnPassantSquare|_] ->
        en_passant_square_to_file(EnPassantSquare, File)
    ;   File = 0  % No en passant
    ),
    zobrist_en_passant(File, Hash).

% Convert en passant square to file number (1-8, or 0 for no en passant)
en_passant_square_to_file(Square, File) :-
    File is (Square mod 8) + 1.

% Calculate side to move hash (only add if black to move)
calculate_side_to_move_hash(white, 0).
calculate_side_to_move_hash(black, Hash) :-
    zobrist_side_to_move(Hash).