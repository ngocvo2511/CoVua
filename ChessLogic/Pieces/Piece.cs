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
                case PieceType.King: return (Color == Player.Black) ? "bK" : "rK";
                case PieceType.Pawn: return (Color == Player.Black) ? "bA" : "rA";
                case PieceType.Rook: return (Color == Player.Black) ? "bCh" : "rCh";
                case PieceType.Bishop: return (Color == Player.Black) ? "bC" : "rC";
                case PieceType.Queen: return (Color == Player.Black) ? "bE" : "rE";
                case PieceType.Knight: return (Color == Player.Black) ? "bH" : "rH";
                default: return (Color == Player.Black) ? "bS" : "rS";
            }
        }
    }
}
