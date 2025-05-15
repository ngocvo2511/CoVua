using ChessLogic;
using ChessLogic.GameStates.GameState;
using System;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;

namespace ChessUI.Menus
{
    /// <summary>
    /// Interaction logic for GameOverMenu.xaml
    /// </summary>
    public partial class GameOverMenu : UserControl
    {
        public event Action<Option> OptionSelected;
        public GameOverMenu(GameState gameState)
        {
            InitializeComponent();

            Result result = gameState.Result;
            WinnerText.Text = GetWinnerText(result.Winner);
            ReasonText.Text = GetReasonText(result.Reason, gameState.CurrentPlayer);
        }

        public GameOverMenu(Result result, Player current)
        {
            InitializeComponent();
            WinnerText.Text = GetWinnerText(result.Winner);
            ReasonText.Text = GetReasonText(result.Reason, current);
        }

        private static string GetWinnerText(Player winner)
        {
            switch (winner)
            {
                case Player.White:
                    return "ĐỎ THẮNG!";
                case Player.Black:
                    return "ĐEN THẮNG!";
                default:
                    return "HÒA!";
            };
        }

        private static string PlayerString(Player player)
        {
            switch (player)
            {
                case Player.White:
                    return "Đỏ";
                case Player.Black:
                    return "Đen";
                default:
                    return "";
            };
        }

        private static string GetReasonText(EndReason reason, Player currentPlayer)
        {
            switch (reason)
            {
                case EndReason.Stalemate: return $"{PlayerString(currentPlayer)} hết nước đi";
                case EndReason.Checkmate: return $"{PlayerString(currentPlayer)} bị chiếu bí";
                case EndReason.InsufficientMaterial: return "Hòa vì thiếu quân";
                case EndReason.FiftyMoveRule: return "Hòa vì 50 nước không ăn quân";
                case EndReason.ThreefoldRepetition: return "Hòa vì lặp lại nước đi 3 lần";
                case EndReason.TimeForfeit: return $"{PlayerString(currentPlayer)} hết thời gian";
                default: return "";
            };
        }

        public static readonly RoutedEvent NewButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "NewButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(GameOverMenu)
        );
        public event RoutedEventHandler NewButtonClicked
        {
            add { AddHandler(NewButtonClickedEvent, value); }
            remove { RemoveHandler(NewButtonClickedEvent, value); }
        }
        private void NewButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(NewButtonClickedEvent));
        }
        public static readonly RoutedEvent HomeButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "HomeButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(GameOverMenu)
        );

        public event RoutedEventHandler HomeButtonClicked
        {
            add { AddHandler(HomeButtonClickedEvent, value); }
            remove { RemoveHandler(HomeButtonClickedEvent, value); }
        }
        private void HomeButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(HomeButtonClickedEvent));
        }

        public static readonly RoutedEvent ReviewButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "ReviewButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(GameOverMenu)
        );
        public event RoutedEventHandler ReviewButtonClicked
        {
            add { AddHandler(ReviewButtonClickedEvent, value); }
            remove { RemoveHandler(ReviewButtonClickedEvent, value); }
        }

        private void ReviewButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(ReviewButtonClickedEvent));
        }

    }
}
