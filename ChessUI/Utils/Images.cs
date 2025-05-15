using System;
using System.Collections.Generic;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using ChessLogic;

namespace ChessUI
{
    public static class Images
    {
        private static readonly Dictionary<PieceType, ImageSource> whiteSources = new Dictionary<PieceType, ImageSource>
           {
               { PieceType.Pawn, LoadImage("Assets/Images/PawnW.png") },
               { PieceType.Bishop, LoadImage("Assets/Images/BishopW.png") },
               { PieceType.Knight, LoadImage("Assets/Images/KnightW.png") },
               { PieceType.Rook, LoadImage("Assets/Images/RookW.png") },
               { PieceType.Queen, LoadImage("Assets/Images/QueenW.png") },
               { PieceType.King, LoadImage("Assets/Images/KingW.png") }
           };

        private static readonly Dictionary<PieceType, ImageSource> blackSources = new Dictionary<PieceType, ImageSource>
           {
               { PieceType.Pawn, LoadImage("Assets/Images/PawnB.png") },
               { PieceType.Bishop, LoadImage("Assets/Images/BishopB.png") },
               { PieceType.Knight, LoadImage("Assets/Images/KnightB.png") },
               { PieceType.Rook, LoadImage("Assets/Images/RookB.png") },
               { PieceType.Queen, LoadImage("Assets/Images/QueenB.png") },
               { PieceType.King, LoadImage("Assets/Images/KingB.png") }
           };

        private static ImageSource LoadImage(string filePath)
        {
            return new BitmapImage(new Uri(filePath, UriKind.Relative));
        }

        public static ImageSource GetImage(Player color, PieceType type)
        {
            switch (color)
            {
                case Player.White: return whiteSources[type];
                case Player.Black: return blackSources[type];
                default: return null;
            };
        }

        public static ImageSource GetImage(Piece piece)
        {
            if (piece == null)
            {
                return null;
            }

            return GetImage(piece.Color, piece.Type);
        }
    }
}
