using ChessLogic;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace ChessUI.Menus
{
    /// <summary>
    /// Interaction logic for PromotionMenu.xaml
    /// </summary>
    public partial class PromotionMenu : UserControl
    {
        public event Action<PieceType> PieceSelected;

        public PromotionMenu(Player player)
        {
            InitializeComponent();

            QueenImg.Source = Images.GetImage(player, PieceType.Queen);
            BishopImg.Source = Images.GetImage(player, PieceType.Bishop);
            RookImg.Source = Images.GetImage(player, PieceType.Rook);
            KnightImg.Source = Images.GetImage(player, PieceType.Knight);
        }

        private void QueenImg_MouseDown(object sender, MouseButtonEventArgs e)
        {
            PieceSelected?.Invoke(PieceType.Queen);
        }

        private void BishopImg_MouseDown(object sender, MouseButtonEventArgs e)
        {
            PieceSelected?.Invoke(PieceType.Bishop);
        }

        private void RookImg_MouseDown(object sender, MouseButtonEventArgs e)
        {
            PieceSelected?.Invoke(PieceType.Rook);
        }

        private void KnightImg_MouseDown(object sender, MouseButtonEventArgs e)
        {
            PieceSelected?.Invoke(PieceType.Knight);
        }
    }
}
