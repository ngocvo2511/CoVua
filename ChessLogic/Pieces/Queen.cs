using System.Collections.Generic;
using System.Linq;

namespace ChessLogic
{
    public class Queen : Piece
    {
        public override PieceType Type => PieceType.Queen;
        public override Player Color { get; set; }

        public Queen(Player color)
        {
            Color = color;
        }
    }
}
