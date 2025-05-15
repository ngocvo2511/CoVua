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

        public abstract IEnumerable<Move> GetMoves(Position from, Board board);

        public virtual bool CanCaptureOpponentKing(Position from, Board board)
        {
            return GetMoves(from, board).Any(move =>
            {
                Piece piece = board[move.ToPos];
                return piece != null && piece.Type == PieceType.King;
            });
        }

        protected IEnumerable<Position> MovePositionsInDir(Position from, Board board, Direction dir)
        {
            for (Position pos = from + dir; Board.IsInside(pos); pos += dir)
            {
                if (board.IsEmpty(pos))
                {
                    yield return pos;
                    continue;
                }

                Piece piece = board[pos];

                if (piece.Color != Color)
                {
                    yield return pos;
                }

                yield break;
            }
        }

        protected IEnumerable<Position> MovePositionsInDirs(Position from, Board board, Direction[] dirs)
        {
            return dirs.SelectMany(dir => MovePositionsInDir(from, board, dir));
        }

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
