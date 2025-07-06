using ChessLogic.Pieces;
using System;
using System.Collections.Generic;
using System.Linq;

namespace ChessLogic
{
    public class Board
    {
        private readonly Piece[,] pieces = new Piece[8, 8];

        public Piece this[int row, int col]
        {
            get { return pieces[row, col]; }
            set { pieces[row, col] = value; }
        }
        public Piece this[Position pos]
        {
            get { return pieces[pos.Row, pos.Column]; }
            set { pieces[pos.Row, pos.Column] = value; }
        }

        public static Board Initial()
        {
            Board board = new Board();
            board.AddStartPieces();
            return board;
        }
        private void AddStartPieces()
        {
            this[0, 0] = new Rook(Player.Black);
            this[0, 1] = new Knight(Player.Black);
            this[0, 2] = new Bishop(Player.Black);
            this[0, 3] = new Queen(Player.Black);
            this[0, 4] = new King(Player.Black);
            this[0, 5] = new Bishop(Player.Black);
            this[0, 6] = new Knight(Player.Black);
            this[0, 7] = new Rook(Player.Black);

            this[7, 0] = new Rook(Player.White);
            this[7, 1] = new Knight(Player.White);
            this[7, 2] = new Bishop(Player.White);
            this[7, 3] = new Queen(Player.White);
            this[7, 4] = new King(Player.White);
            this[7, 5] = new Bishop(Player.White);
            this[7, 6] = new Knight(Player.White);
            this[7, 7] = new Rook(Player.White);

            for (int c = 0; c < 8; c++)
            {
                this[1, c] = new Pawn(Player.Black);
                this[6, c] = new Pawn(Player.White);
            }
        }

        public bool IsEmpty(Position pos)
        {
            return this[pos] == null;
        }


        public static Board FromPrologPosition(Dictionary<Player, Dictionary<PieceType, List<int>>> prologPosition)
        {
            Board board = new Board();

            foreach (var playerEntry in prologPosition)
            {
                Player player = playerEntry.Key;
                var pieceDict = playerEntry.Value;
                foreach (var pieceEntry in pieceDict)
                {
                    PieceType type = pieceEntry.Key;
                    List<int> positions = pieceEntry.Value;
                    foreach (int pos in positions)
                    {
                        int row = 7 - (pos / 8);
                        int col = pos % 8;
                        Piece piece = null;
                        switch (type)
                        {
                            case PieceType.Pawn:
                                piece = new Pawn(player);
                                break;
                            case PieceType.Rook:
                                piece = new Rook(player);
                                break;
                            case PieceType.Knight:
                                piece = new Knight(player);
                                break;
                            case PieceType.Bishop:
                                piece = new Bishop(player);
                                break;
                            case PieceType.Queen:
                                piece = new Queen(player);
                                break;
                            case PieceType.King:
                                piece = new King(player);
                                break;
                        }
                        if (piece != null)
                        {
                            board[row, col] = piece;
                        }
                    }
                }
            }
            return board;
        }
    }
}
