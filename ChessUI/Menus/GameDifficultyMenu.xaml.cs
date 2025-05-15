using System.Windows;
using System.Windows.Controls;

namespace ChessUI.Menus
{
    /// <summary>
    /// Interaction logic for GameDifficultyMenu.xaml
    /// </summary>
    public partial class GameDifficultyMenu : UserControl
    {
        public GameDifficultyMenu()
        {
            InitializeComponent();
        }
        public static readonly RoutedEvent BackButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "BackButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(GameDifficultyMenu)
        );
        public event RoutedEventHandler BackButtonClicked
        {
            add { AddHandler(BackButtonClickedEvent, value); }
            remove { RemoveHandler(BackButtonClickedEvent, value); }
        }
        private void BackButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(BackButtonClickedEvent));
        }

        public static readonly RoutedEvent PlayEasyBot = EventManager.RegisterRoutedEvent(
           "PlayEasyBotButtonClicked",
           RoutingStrategy.Bubble,
           typeof(RoutedEventHandler),
           typeof(SelectGameModeMenu)
        );

        public event RoutedEventHandler PlayEasyBotButtonClicked
        {
            add { AddHandler(PlayEasyBot, value); }
            remove { RemoveHandler(PlayEasyBot, value); }
        }
        private void EasyButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(PlayEasyBot));
        }

        public static readonly RoutedEvent PlayNormalBot = EventManager.RegisterRoutedEvent(
           "PlayNormalBotButtonClicked",
           RoutingStrategy.Bubble,
           typeof(RoutedEventHandler),
           typeof(SelectGameModeMenu)
       );

        public event RoutedEventHandler PlayNormalBotButtonClicked
        {
            add { AddHandler(PlayNormalBot, value); }
            remove { RemoveHandler(PlayNormalBot, value); }
        }
        private void NormalButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(PlayNormalBot));
        }

        public static readonly RoutedEvent PlayHardBot = EventManager.RegisterRoutedEvent(
           "PlayHardBotButtonClicked",
           RoutingStrategy.Bubble,
           typeof(RoutedEventHandler),
           typeof(SelectGameModeMenu)
       );

        public event RoutedEventHandler PlayHardBotButtonClicked
        {
            add { AddHandler(PlayHardBot, value); }
            remove { RemoveHandler(PlayHardBot, value); }
        }
        private void HardButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(PlayHardBot));
        }
    }
}
