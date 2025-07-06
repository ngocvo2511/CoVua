using System.Collections.Generic;
using System.Linq;

namespace ChessLogic
{
    public class Pawn : Piece
    {
        public override PieceType Type => PieceType.Pawn;
        public override Player Color { get; set; }

        public Pawn(Player color)
        {
            Color = color;
        }
    }
}
