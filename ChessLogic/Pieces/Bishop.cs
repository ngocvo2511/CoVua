using System.Collections.Generic;
using System.Linq;

namespace ChessLogic
{
    public class Bishop : Piece
    {
        public override PieceType Type => PieceType.Bishop;
        public override Player Color { get; set; }

        public Bishop(Player color)
        {
            Color = color;
        }
    }
}
