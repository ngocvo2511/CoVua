using System.Windows;
using System.Windows.Controls;

namespace ChessUI.Menus
{
    /// <summary>
    /// Interaction logic for SelectGameModeMenu.xaml
    /// </summary>
    public partial class SelectGameModeMenu : UserControl
    {
        public SelectGameModeMenu()
        {
            InitializeComponent();
        }

        public static readonly RoutedEvent CloseButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "CloseButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(SelectGameModeMenu)
        );
        public event RoutedEventHandler CloseButtonClicked
        {
            add { AddHandler(CloseButtonClickedEvent, value); }
            remove { RemoveHandler(CloseButtonClickedEvent, value); }
        }

        private void CloseButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(CloseButtonClickedEvent));
        }

        public static readonly RoutedEvent PlayWithBotButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "PlayWithBotButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(SelectGameModeMenu)
        );

        public event RoutedEventHandler PlayWithBotButtonClicked
        {
            add { AddHandler(PlayWithBotButtonClickedEvent, value); }
            remove { RemoveHandler(PlayWithBotButtonClickedEvent, value); }
        }

        private void PlayWithBotButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(PlayWithBotButtonClickedEvent));
        }

        public static readonly RoutedEvent TwoPlayerButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "TwoPlayerButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(SelectGameModeMenu)
        );

        public event RoutedEventHandler TwoPlayerButtonClicked
        {
            add { AddHandler(TwoPlayerButtonClickedEvent, value); }
            remove { RemoveHandler(TwoPlayerButtonClickedEvent, value); }
        }

        private void TwoPlayerButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(TwoPlayerButtonClickedEvent));
        }


        public static readonly RoutedEvent PlayOnlineButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "PlayOnlineButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(SelectGameModeMenu)
        );

        public event RoutedEventHandler PlayOnlineButtonClicked
        {
            add { AddHandler(PlayOnlineButtonClickedEvent, value); }
            remove { RemoveHandler(PlayOnlineButtonClickedEvent, value); }
        }
        private void PlayOnlineButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(PlayOnlineButtonClickedEvent));
        }
    }
}
