using System.Collections.Generic;
using System.Linq;

namespace ChessLogic
{
    public class King : Piece
    {
        public override PieceType Type => PieceType.King;
        public override Player Color { get; }

        public King(Player color)
        {
            Color = color;
        }

        public override Piece Copy()
        {
            King copy = new King(Color);
            copy.HasMoved = HasMoved;
            return copy;
        }
    }
}
