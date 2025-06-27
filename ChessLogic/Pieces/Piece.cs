using System.Collections.Generic;
using System.Linq;

namespace ChessLogic
{
    public abstract class Piece
    {
        public Player bottomPlayer;
        public abstract PieceType Type { get; }
        public abstract Player Color { get; }
        public bool HasMoved { get; set; } = false;
        public abstract Piece Copy();

        public override string ToString() // chua
        {
            switch (Type)
            {
                case PieceType.King: return (Color == Player.Black) ? "bK" : "wK";
                case PieceType.Pawn: return (Color == Player.Black) ? "bP" : "wP";
                case PieceType.Rook: return (Color == Player.Black) ? "bR" : "wR";
                case PieceType.Bishop: return (Color == Player.Black) ? "bB" : "wB";
                case PieceType.Queen: return (Color == Player.Black) ? "bQ" : "wQ";
                case PieceType.Knight: return (Color == Player.Black) ? "bKn" : "wKn";
                default: return "Unknown Type";
            }
        }
    }
}
