using System.Collections.Generic;
using System.Linq;

namespace ChessLogic
{
    public class King : Piece
    {
        public override PieceType Type => PieceType.King;
        public override Player Color { get; set; }

        public King(Player color)
        {
            Color = color;
        }
    }
}
