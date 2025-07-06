using System.Collections.Generic;
using System.Linq;

namespace ChessLogic
{
    public class Knight : Piece
    {
        public override PieceType Type => PieceType.Knight;
        public override Player Color { get; set; }

        public Knight(Player color)
        {
            Color = color;
        }
    }
}
